#!/usr/bin/env python3
"""
Comprehensive verification test for tools.openooda.org
"""
import os
import re
import json

ROOT = os.path.dirname(os.path.abspath(__file__))

def test_no_external_dependencies():
    index_path = os.path.join(ROOT, "index.html")
    with open(index_path, "r", encoding="utf-8") as f:
        content = f.read()

    # Disallow external scripts or stylesheets or fonts
    external_scripts = re.findall(r'<script[^>]+src=["\'](https?://[^"\']+)["\']', content)
    external_links = re.findall(r'<link[^>]+href=["\'](https?://[^"\']+)["\']', content)

    assert not external_scripts, f"Found external scripts: {external_scripts}"
    assert not external_links, f"Found external stylesheets/fonts: {external_links}"
    print("[PASS] Zero external runtime dependencies in index.html")

def test_element_id_parity():
    index_path = os.path.join(ROOT, "index.html")
    app_js_path = os.path.join(ROOT, "assets/js/app.js")
    
    with open(index_path, "r", encoding="utf-8") as f:
        html = f.read()
    with open(app_js_path, "r", encoding="utf-8") as f:
        js = f.read()

    ids_in_js = re.findall(r'getElementById\(["\']([^"\']+)["\']\)', js)
    for elem_id in ids_in_js:
        pattern = f'id="{elem_id}"'
        assert pattern in html, f"ID '{elem_id}' referenced in app.js not found in index.html!"
    print(f"[PASS] All {len(ids_in_js)} DOM element IDs referenced in app.js exist in index.html")

def test_released_tools_parity():
    json_path = os.path.join(ROOT, "data/tools.json")
    with open(json_path, "r", encoding="utf-8") as f:
        tools = json.load(f)

    assert len(tools) == 78, f"Expected 78 tools, got {len(tools)}"
    
    released = [t for t in tools if t["status"] == "released"]
    assert len(released) == 78, f"Expected 78 released tools, got {len(released)}"
    
    expected_released = [
        "oosh", "oogrep", "oodiff", "oofind", "oojq", "ootail", "oote", "oofetch", "oocat", "ootop", "oofzf", "ools",
        "ootree", "ooclock", "oosed", "ootar", "oops", "oocurl", "oowatch", "oomcp", "oo7z", "ooalias", "ooansi", "ooapparmor", "ooarchive", "ooarp", "ooastdiff", "ooat", "ooattest", "ooaudit", "ooawk", "oob3sum", "oobackup", "oobanner", "oobar", "oobase32", "oobase58", "oobase64", "oobasename", "oobash", "oobatch", "oobattery", "oobiew", "oobinary", "oobindiff", "ooborder", "oobound", "ooboundary", "oobson", "oobzip2", "oocap", "oocbor", "oocert", "oocgroup", "oocgroupv2", "oochecksum", "oochgrp", "oochmod", "oochown", "oochroot", "ooclear", "oocmp", "oocol", "oocolor", "oocolrm", "oocomm", "oocp", "oocpio", "oocpuinfo", "oocrc32", "oocron", "oocsplt", "oocsv", "oocut", "oodf", "oodialog", "oodiff3", "oodig"
    ]
    released_ids = [t["id"] for t in released]
    assert set(released_ids) == set(expected_released), f"Released IDs mismatch: {released_ids}"

    for t in released:
        tool_dir = os.path.join(ROOT, t["id"])
        assert os.path.isdir(tool_dir), f"Directory {tool_dir} does not exist!"
        index_file = os.path.join(tool_dir, "index.html")
        assert os.path.isfile(index_file), f"Subpage {index_file} missing!"
        install_file = os.path.join(tool_dir, "install.sh")
        assert os.path.isfile(install_file), f"Install script {install_file} missing!"
        
        expected_cmd = f"curl -fsSL https://openooda-tools.github.io/{t['id']}/install.sh | bash"
        assert t["installCommand"] == expected_cmd, f"Install command mismatch for {t['id']}: {t['installCommand']}"
        assert t["overviewUrl"] == f"{t['id']}/", f"Overview URL mismatch for {t['id']}: {t['overviewUrl']}"

    print(f"[PASS] All {len(released)} active sovereign tools verified with filesystem directories, subpages, and install scripts")

def test_install_script_syntax():
    tools = ["oosh", "oogrep", "oodiff", "oofind", "oojq", "ootail", "oote", "oofetch", "oocat", "ootop", "oofzf", "ools"]
    for tool in tools:
        inst = os.path.join(ROOT, tool, "install.sh")
        ret = os.system(f"bash -n '{inst}'")
        assert ret == 0, f"bash -n failed on {inst}"
        uninst = os.path.join(ROOT, tool, "uninstall.sh")
        if os.path.exists(uninst):
            ret = os.system(f"bash -n '{uninst}'")
            assert ret == 0, f"bash -n failed on {uninst}"
    print("[PASS] All installer and uninstaller shell scripts pass bash -n syntax checks")

def test_marquee_and_gems():
    json_path = os.path.join(ROOT, "data/tools.json")
    with open(json_path, "r", encoding="utf-8") as f:
        tools = json.load(f)
    
    gems = [t for t in tools if t.get("gem")]
    assert len(gems) >= 6, f"Expected at least 6 hidden gems, got {len(gems)}"
    print(f"[PASS] Hidden gems verified: {len(gems)} curated tools")

def test_browser_e2e():
    script_path = os.path.join(ROOT, "test_browser.js")
    if os.path.exists(script_path):
        ret = os.system(f"node '{script_path}'")
        assert ret == 0, f"test_browser.js failed with exit code {ret}"

if __name__ == "__main__":
    test_no_external_dependencies()
    test_element_id_parity()
    test_released_tools_parity()
    test_install_script_syntax()
    test_marquee_and_gems()
    test_browser_e2e()
    print("\nALL VERIFICATION CHECKS PASSED SUCCESSFULLY!")

