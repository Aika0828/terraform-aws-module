# ecv-tf

A small CLI for using this module library like a package manager: start a
project, browse modules, install them at a pinned release, and upgrade them later.
It needs only **bash** and **git**. Terraform still does the real work.

```
ecv-tf config     show or change settings (repo, ref, dest, source)
ecv-tf init       scaffold a new Terraform project that uses the library
ecv-tf list       list modules (--versions for releases, -i for installed)
ecv-tf install    add modules:  ecv-tf install -m vpc,alb --write
ecv-tf upgrade    move modules to a newer release (--check, --to, --self)
ecv-tf help       help for any command:  ecv-tf help install
```

## Install

```bash
# from a clone of this repo
./cli/install.sh                       # → ~/.local/bin/ecv-tf

# or in one go (needs GitLab access over SSH)
git clone --depth 1 git@gitlab.ecvmsp.com:ecv-ph-tech-team/ph-modernization-team/terraform-aws-module.git /tmp/tfmod \
  && /tmp/tfmod/cli/install.sh && rm -rf /tmp/tfmod
```

Use `PREFIX=/usr/local/bin` to install elsewhere. Later, update the CLI with
`ecv-tf upgrade --self`.

Can't reach GitLab? Point it at the GitHub mirror:

```bash
ecv-tf config set --global repo https://github.com/Aika0828/terraform-aws-module.git
```

## Quick start

```bash
ecv-tf init my-app -p myapp -e dev     # scaffold, pin the latest release
cd my-app
ecv-tf list                             # browse modules by domain
ecv-tf install -m vpc,ec2-bastion --write
$EDITOR env/dev.tfvars                  # set map_migrated, then fill module inputs in main.tf
terraform init -backend-config=env/dev.s3.tfbackend
terraform plan -var-file=env/dev.tfvars
```

## What `init` creates

| File | Purpose |
|---|---|
| `.ecv-tf` | Project settings, with the library release pinned. Commit it. |
| `ecv-tf.lock` | Every installed module with its release and exact commit. Commit it. |
| `versions.tf` | Terraform `>= 1.10`, AWS provider `~> 6.0` |
| `providers.tf` | Default provider and the `aws.workload` alias, both with the 3 standard tags |
| `variables.tf`, `locals.tf` | `project_name`, `environment`, `region`, `map_migrated`, `local.name` |
| `backend.tf` + `env/<env>.s3.tfbackend` | S3 backend with native locking (`use_lockfile`). Bucket and key are set per environment. |
| `env/<env>.tfvars` | Values for each environment (one root, a tfvars file per env) |
| `main.tf`, `.gitignore` | |

Existing files are never overwritten unless you pass `--force`. Use
`--backend local` to skip the S3 backend.

## Modules: names, sources, the lock file

- You can name a module as `vpc`, `aws-vpc` or `networking/aws-vpc`.
- **`source = modules`** (default): modules are copied into
  `modules/terraform-aws-modules/<domain>/<name>` and referenced by local path.
  Commit that folder or run `ecv-tf install` (no arguments) to restore it
  from `ecv-tf.lock`, like `npm ci`.
- **`source = git`**: nothing is copied. Blocks use
  `git::<repo>//modules/<domain>/<name>?ref=<tag>`, and `upgrade` rewrites the
  `?ref=` in your top-level `*.tf` files.
- `ecv-tf.lock` records the commit for every module. If someone moves a tag
  later, `install` warns you and stays on the locked commit.

## Upgrading

```bash
ecv-tf upgrade --check          # what would change, and which modules' code actually changed
ecv-tf upgrade                  # everything → latest release
ecv-tf upgrade vpc --to v0.3.0  # one module, a specific release
```

After upgrading, review the diff and run `terraform init -upgrade && terraform plan`.

## Settings

Settings are applied in this order (first wins): command flags, `ECV_TF_*`
environment variables, the project `.ecv-tf` file, the global
`~/.config/ecv-tf/config` file, then the built-in defaults.

| Key | Default | |
|---|---|---|
| `repo` | GitLab over SSH | library git URL |
| `ref` | `latest` | `init` and the first `install` pin this to a real tag |
| `dest` | `modules/terraform-aws-modules` | where copied modules go |
| `source` | `modules` | `modules` or `git` (`vendor` is accepted as an old name for `modules`) |
