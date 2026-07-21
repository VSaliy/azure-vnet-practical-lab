import pathlib
import re
import unittest
from urllib.parse import unquote

ROOT = pathlib.Path(__file__).resolve().parents[2]
TF = ROOT / "infrastructure" / "terraform"


class RepositoryPolicyTests(unittest.TestCase):
    def test_stage_roots_exist(self):
        roots = sorted((TF / "stages").glob("[0-9][0-9]-*"))
        self.assertEqual([p.name[:2] for p in roots], [f"{n:02}" for n in range(1, 9)])

    def test_provider_and_terraform_constraints(self):
        for versions in (TF / "stages").glob("*/versions.tf"):
            text = versions.read_text(encoding="utf-8")
            self.assertIn('>= 1.7.0, < 2.0.0', text, versions)
            self.assertIn('>= 4.81.0, < 5.0.0', text, versions)

    def test_stage_roots_commit_provider_locks(self):
        for stage in (TF / "stages").glob("[0-9][0-9]-*"):
            self.assertTrue((stage / ".terraform.lock.hcl").is_file(), stage)

    def test_default_outbound_is_explicitly_disabled(self):
        text = (TF / "modules/network/main.tf").read_text(encoding="utf-8")
        self.assertRegex(text, r"default_outbound_access_enabled\s*=\s*false")

    def test_no_forbidden_default_resources(self):
        all_tf = "\n".join(p.read_text(encoding="utf-8") for p in TF.rglob("*.tf"))
        forbidden = (
            "azurerm_nat_gateway",
            "azurerm_firewall",
            "azurerm_bastion_host",
            "azurerm_public_ip",
            "azurerm_virtual_network_gateway",
            "azurerm_log_analytics_workspace",
            "azurerm_network_security_group_flow_log",
        )
        for resource in forbidden:
            self.assertNotRegex(all_tf, rf'resource\s+"{resource}"', resource)

    def test_exact_allocations_are_encoded(self):
        expected = {
            "01-minimal-vnet": "10.20.0.0/20",
            "02-three-tier-segmentation": "10.20.16.0/20",
            "03-routing-and-nsg-diagnostics": "10.20.84.0/23",
            "04-vnet-peering": "10.20.80.0/24",
            "05-hub-and-spoke": "10.20.32.0/20",
            "06-private-service-access": "10.20.82.0/23",
            "07-monitoring": "10.20.86.0/23",
            "08-troubleshooting": "10.20.88.0/21",
        }
        for stage, cidr in expected.items():
            text = (TF / "stages" / stage / "main.tf").read_text(encoding="utf-8")
            self.assertIn(cidr, text, stage)
        hub = (TF / "stages/05-hub-and-spoke/main.tf").read_text(encoding="utf-8")
        self.assertIn("10.20.48.0/20", hub)
        self.assertIn("10.20.64.0/20", hub)
        peer = (TF / "stages/04-vnet-peering/main.tf").read_text(encoding="utf-8")
        self.assertIn("10.20.81.0/24", peer)

    def test_stage02_exact_four_vm_definition_and_matrix(self):
        text = (TF / "stages/02-three-tier-segmentation/main.tf").read_text(encoding="utf-8")
        for name in ("management", "web", "application", "data"):
            self.assertRegex(text, rf"\b{name}\s*=")
        self.assertIn("length(local.endpoints) == 4", text)
        output = (TF / "stages/02-three-tier-segmentation/outputs.tf").read_text(encoding="utf-8")
        for port in ("22", "8080", "5432"):
            self.assertIn(f"port = {port}", output)

    def test_mandatory_tags(self):
        text = (TF / "modules/conventions/main.tf").read_text(encoding="utf-8")
        for key in ("environment", "owner", "expires-on", "managed-by", "lab-stage"):
            self.assertRegex(text, re.escape(key) + r"\s*=")

    def test_no_real_tfvars_or_state(self):
        bad = []
        for path in ROOT.rglob("*"):
            if path.is_file() and (
                path.name.endswith(".tfstate")
                or path.name.endswith(".tfplan")
                or (path.name.endswith(".tfvars") and not path.name.endswith(".tfvars.example"))
                or (
                    path.name.endswith(".tfvars.json")
                    and not path.name.endswith(".tfvars.example.json")
                )
            ):
                bad.append(str(path.relative_to(ROOT)))
        self.assertEqual(bad, [])

    def test_chargeable_feature_defaults_are_off(self):
        variables = "\n".join(
            p.read_text(encoding="utf-8")
            for p in (TF / "stages").glob("*/variables.tf")
        )
        for feature in (
            "enable_live",
            "enable_private_endpoint",
            "enable_vnet_flow_logs",
            "enable_private_dns",
        ):
            matches = re.findall(
                rf'variable\s+"{feature}"\s*\{{(.*?)\n\}}',
                variables,
                flags=re.DOTALL,
            )
            self.assertTrue(matches, feature)
            for body in matches:
                self.assertRegex(body, r"default\s*=\s*false", feature)

    def test_every_stage_has_a_blocking_deployment_guard(self):
        for stage in (TF / "stages").glob("[0-9][0-9]-*"):
            text = (stage / "main.tf").read_text(encoding="utf-8")
            self.assertRegex(
                text,
                r'resource\s+"terraform_data"\s+"deployment_guard"',
                stage,
            )
            self.assertIn("precondition {", text, stage)

    def test_internal_markdown_links_resolve(self):
        missing = []
        for document in ROOT.rglob("*.md"):
            text = document.read_text(encoding="utf-8")
            for target in re.findall(r"\[[^\]]+\]\(([^)]+)\)", text):
                if target.startswith(("http://", "https://", "mailto:", "#")):
                    continue
                path_text = unquote(target.split("#", 1)[0].split("?", 1)[0])
                if not path_text:
                    continue
                resolved = (document.parent / path_text).resolve()
                if not resolved.exists():
                    missing.append(f"{document.relative_to(ROOT)} -> {target}")
        self.assertEqual(missing, [])


if __name__ == "__main__":
    unittest.main()
