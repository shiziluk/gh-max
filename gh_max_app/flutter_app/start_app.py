import subprocess
import os
import sys

# Flutter应用路径（自动检测脚本所在目录下的Release文件夹）
script_dir = os.path.dirname(os.path.abspath(__file__))
release_dir = os.path.join(script_dir, "Release")
flutter_exe = os.path.join(release_dir, "flutter_app.exe")

print(f"启动Flutter应用: {flutter_exe}")

if not os.path.exists(flutter_exe):
    print(f"错误: 未找到 {flutter_exe}")
    print("请确保Release文件夹与start_app.py在同一目录下")
    sys.exit(1)

try:
    # 使用当前目录启动应用
    process = subprocess.Popen(
        [flutter_exe],
        cwd=release_dir,
        creationflags=subprocess.CREATE_NEW_CONSOLE if sys.platform == "win32" else 0
    )
    print(f"应用已启动，进程ID: {process.pid}")
except Exception as e:
    print(f"启动失败: {e}")
    sys.exit(1)
