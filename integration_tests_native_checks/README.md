# Native-check package consumer

This Fusion-only integration project installs dbt-project-evaluator as a local
dependency and opts into its v2 native checks. It verifies the same root-project
configuration that package users apply, including disabling the legacy models.
