# Steps to Compile and Package Your Python Module

## 1. Create `setup.py`
This compiles your `.pyx` file into a `.pyd` extension module using Cython.

    ```python
    from setuptools import setup
    from Cython.Build import cythonize

    setup(
        ext_modules=cythonize("checkcp311_win_amd64.pyx", compiler_directives={'language_level': "3"})
    )

Note: Make sure the .pyx file is named exactly checkcp311_win_amd64.pyx.

2. Refactor Your Logic into a Callable Module
Rename your original check.py to checkcp311_win_amd64.pyx.
Replace the entry point:
From:
python
if __name__ == "__main__":
    asyncio.run(main())

Run

To:
python
def run():
    asyncio.run(main())

Run

This modification makes the module callable from a launcher script.

3. Create a Lightweight Launcher: check.py
    ```python
    import checkcp311_win_amd64 as core  # Match the name of your compiled .pyd

    core.run()

Run

This script will be packaged into the .exe and will call your obfuscated logic.

4. Compile the .pyx into .pyd
Run the following command:

    ```bash
    python setup.py build_ext --inplace

This generates:

checkcp311_win_amd64.cp311-win_amd64.pyd

Rename it to: checkcp311_win_amd64.pyd.

5. Package with PyInstaller
To package the file alone without the JSON file it depends on. Console window is displayed:

    ```bash
    pyinstaller --onefile --hidden-import=aiohttp --hidden-import=pandas --add-binary "checkcp311_win_amd64.pyd;." check.py

To package the file alone without the JSON file; hidden console window:

       ``` bash
    pyinstaller --onefile --noconsole --hidden-import=aiohttp --hidden-import=pandas --add-binary "checkcp311_win_amd64.pyd;." check.py

To package the executable file together with its data; hidden console window:

    
    pyinstaller --onefile --noconsole --hidden-import=aiohttp --hidden-import=pandas --add-binary "checkcp311_win_amd64.pyd;." --add-data "config.json;." check.py

6. Final Deployment Folder
dist/
├── check.exe
├── config.json  ← manually placed, editable by users
├── time.json 
