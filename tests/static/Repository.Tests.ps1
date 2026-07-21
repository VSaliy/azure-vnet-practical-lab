#requires -Version 7.0
Describe 'Repository safety policy' {
    It 'has eight independent Terraform stage roots' {
        $roots = @(Get-ChildItem "$PSScriptRoot/../../infrastructure/terraform/stages" -Directory)
        $roots.Count | Should -Be 8
    }

    It 'does not define a public IP resource' {
        $content = Get-ChildItem "$PSScriptRoot/../../infrastructure/terraform" -Recurse -Filter *.tf |
            Get-Content -Raw
        ($content -join "`n") | Should -Not -Match 'resource\s+"azurerm_public_ip"'
    }

    It 'explicitly disables default subnet outbound access' {
        $network = Get-Content "$PSScriptRoot/../../infrastructure/terraform/modules/network/main.tf" -Raw
        $network | Should -Match 'default_outbound_access_enabled\s*=\s*false'
    }
}
