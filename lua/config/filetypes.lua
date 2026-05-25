vim.filetype.add({
  pattern = {
    -- Helm chart templates
    [".*/templates/.*%.ya?ml"] = "helm",
    [".*/templates/.*%.tpl"] = "helm",

    -- GitHub Actions workflows
    [".*/%.github/workflows/.*%.ya?ml"] = "yaml.github",

    -- Docker Compose, if you add it later
    [".*/docker%-compose%.ya?ml"] = "yaml.docker-compose",
    [".*/compose%.ya?ml"] = "yaml.docker-compose",

    -- Kustomize, if you add overlays later
    [".*/kustomization%.ya?ml"] = "yaml",
  },

  filename = {
    ["Dockerfile"] = "dockerfile",
    [".env"] = "dotenv",
    [".env.example"] = "dotenv",
  },

  extension = {
    tf = "terraform",
    tfvars = "terraform",
    hcl = "hcl",
  },
})
