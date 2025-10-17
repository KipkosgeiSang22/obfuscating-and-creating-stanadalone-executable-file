# Obfuscating and Packaging a Python Script with Cython and PyInstaller

This guide outlines the steps to obfuscate your Python logic using Cython, compile it into a `.pyd` extension, and package it into a standalone `.exe` using PyInstaller.

---

## 🛠️ Step 1: Create `setup.py`

This script compiles your `.pyx` file into a `.pyd` extension module using Cython.

```python
from setuptools import setup
from Cython.Build import cythonize

setup(
    ext_modules=cythonize("checkcp311_win_amd64.pyx", compiler_directives={'language_level': "3"})
)


✅ Make sure the .pyx file is named exactly: checkcp311_win_amd64.pyx

🔄 Step 2: Refactor Your Logic into a Callable Module
Rename your original check.py to:
checkcp311_win_amd64.pyx


Replace the entry point:
From:
if __name__ == "__main__":
    asyncio.run(main())


To:
def run():
    asyncio.run(main())


This makes the module callable from a launcher script.

🚀 Step 3: Create a Lightweight Launcher (check.py)
import checkcp311_win_amd64 as core  # Match the name of your compiled .pyd

core.run()


This script will be packaged into the .exe and will call your obfuscated logic.

⚙️ Step 4: Compile the .pyx into .pyd
Run:
python setup.py build_ext --inplace


This generates:
checkcp311_win_amd64.cp311-win_amd64.pyd


✅ Rename it to:
checkcp311_win_amd64.pyd



📦 Step 5: Package with PyInstaller
Run:
pyinstaller --onefile --hidden-import=aiohttp --hidden-import=pandas --add-binary "checkcp311_win_amd64.pyd;." check.py


This bundles everything into a single .exe located in the dist/ folder.

📁 Step 6: Final Deployment Folder Structure
dist/
├── check.exe
├── config.json   # Manually placed, editable by users



✅ Summary of What You Achieved
- ✔️ Obfuscated core logic using Cython
- ✔️ Converted it into a .pyd extension
- ✔️ Created a clean launcher script
- ✔️ Packaged everything into a standalone .exe
- ✔️ Preserved user-editable config
- ✔️ Ensured runtime compatibility with aiohttp and pandas

📄 License
This project is licensed under the MIT License.

👤 Author
© 2025 Joshua
