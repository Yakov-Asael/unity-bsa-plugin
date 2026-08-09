#!/usr/bin/env python3
"""Validate the Unity BSA marketplace: manifests, skill completeness, and README discipline.

Run from the repo root. Exits non-zero (with a list of problems) if any rule fails.
Enforced rules:
  - marketplace.json and every plugin.json are valid JSON with a `name`.
  - every plugin listed in marketplace.json has an existing `source` dir + plugin.json.
  - every plugin has a README.md.
  - every skill (skills/*/) has: a valid SKILL.md (frontmatter name == dir, description present),
    a README.md, and an assets/banner.png.
  - every skill is listed in its plugin's README.md (so the plugin README is always kept current).
"""
import json
import os
import re
import sys

ROOT = os.getcwd()
errors = []
warnings = []


def err(msg):
    errors.append(msg)


def warn(msg):
    warnings.append(msg)


def load_json(path):
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except FileNotFoundError:
        err(f"missing file: {path}")
    except json.JSONDecodeError as e:
        err(f"invalid JSON in {path}: {e}")
    return None


def frontmatter(path):
    with open(path, encoding="utf-8") as f:
        text = f.read()
    if not text.startswith("---"):
        return None, text
    parts = text.split("---", 2)
    return (parts[1] if len(parts) >= 3 else ""), text


def validate_marketplace():
    mp = load_json(".claude-plugin/marketplace.json")
    if not mp:
        return
    if "name" not in mp:
        err("marketplace.json missing `name`")
    root_readme = ""
    if os.path.isfile("README.md"):
        with open("README.md", encoding="utf-8") as f:
            root_readme = f.read()
    else:
        err("root README.md is missing")
    for entry in mp.get("plugins", []):
        name = entry.get("name", "")
        src = entry.get("source", "")
        rel = src[2:] if src.startswith("./") else src
        if not os.path.isfile(os.path.join(rel, ".claude-plugin", "plugin.json")):
            err(f"marketplace plugin '{name}' source has no plugin.json: {src}")
        if name and name not in root_readme:
            err(f"marketplace plugin '{name}' is not listed in the root README.md "
                f"(add it to the 'What's inside' table so the marketplace README stays current)")


def validate_plugin(plugin_dir):
    pj = load_json(os.path.join(plugin_dir, ".claude-plugin", "plugin.json"))
    if pj and "name" not in pj:
        err(f"{plugin_dir}/.claude-plugin/plugin.json missing `name`")

    plugin_readme_path = os.path.join(plugin_dir, "README.md")
    if not os.path.isfile(plugin_readme_path):
        err(f"{plugin_dir} has no README.md")
        plugin_readme = ""
    else:
        with open(plugin_readme_path, encoding="utf-8") as f:
            plugin_readme = f.read()

    skills_dir = os.path.join(plugin_dir, "skills")
    if not os.path.isdir(skills_dir):
        return
    for name in sorted(os.listdir(skills_dir)):
        sdir = os.path.join(skills_dir, name)
        if not os.path.isdir(sdir):
            continue
        skill_md = os.path.join(sdir, "SKILL.md")
        if not os.path.isfile(skill_md):
            err(f"skill '{name}' has no SKILL.md")
            continue
        fm, text = frontmatter(skill_md)
        if fm is None:
            err(f"skill '{name}' SKILL.md has no YAML frontmatter")
        else:
            if f"name: {name}" not in fm:
                err(f"skill '{name}' frontmatter `name` must equal the directory name")
            if "description:" not in fm:
                err(f"skill '{name}' frontmatter missing `description`")
        if not os.path.isfile(os.path.join(sdir, "README.md")):
            err(f"skill '{name}' has no README.md")
        if not os.path.isfile(os.path.join(sdir, "assets", "banner.png")):
            err(f"skill '{name}' has no assets/banner.png")
        if name not in plugin_readme:
            err(f"skill '{name}' is not listed in {plugin_dir}/README.md "
                f"(add it to the skills table so the plugin README stays current)")
        if re.search(r"not yet active|coming soon|work in progress", text, re.I):
            warn(f"skill '{name}' still contains a WIP marker")


def main():
    validate_marketplace()
    plugins_root = "plugins"
    if os.path.isdir(plugins_root):
        for name in sorted(os.listdir(plugins_root)):
            pdir = os.path.join(plugins_root, name)
            if os.path.isfile(os.path.join(pdir, ".claude-plugin", "plugin.json")):
                validate_plugin(pdir)

    for w in warnings:
        print(f"::warning:: {w}")
    if errors:
        print("\nValidation FAILED:")
        for e in errors:
            print(f"  - {e}")
        sys.exit(1)
    print("Validation passed: manifests, skills, and README discipline all OK.")


if __name__ == "__main__":
    main()
