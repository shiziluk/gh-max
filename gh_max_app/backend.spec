# -*- mode: python ; coding: utf-8 -*-
# GH-Max Backend PyInstaller spec

import sys
from pathlib import Path

block_cipher = None

# Backend source directory
backend_dir = Path(__file__).parent / "gh_max_app" / "backend"

a = Analysis(
    [str(backend_dir / "app.py")],
    pathex=[str(backend_dir)],
    binaries=[],
    datas=[
        # Include data directory
        (str(backend_dir / "data"), "data"),
        # Include logs directory
        (str(backend_dir / "logs"), "logs"),
    ],
    hiddenimports=[
        "akshare",
        "flask",
        "flask_cors",
        "numpy",
        "pandas",
        "requests",
        "bs4",
        "lxml",
        "schedule",
        "apscheduler",
        "plyer",
        "json",
        "sqlite3",
        "threading",
        "re",
        "random",
        "traceback",
        "signal",
        "os",
        "datetime",
        "typing",
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[
        "tkinter",
        "matplotlib",
        "scipy",
        "PIL",
        "cv2",
        "tensorflow",
        "torch",
    ],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.zipfiles,
    a.datas,
    [],
    name="gh_max_backend",
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=True,  # Show console for backend server logs
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon=None,
)
