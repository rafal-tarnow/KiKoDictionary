import os

# Lista dozwolonych rozszerzeń
allowed_extensions = ['.ini', '.py', '.cpp', '.c', '.hpp', '.h', '.txt', '.qml']

# Lista zablokowanych katalogów
blocked_dirs = ['venv', '__pycache__', '.git', 'migrations', 'build']

# Lista zablokowanych plików (pełne nazwy plików)
blocked_files = ['dump_output.txt', 'dump_project.py', '.gitignore', 'alembic.ini', '__init__.py']

# Ścieżka startowa (można zmienić na inny katalog)
start_path = '.'

# Plik wynikowy
output_file = 'dump_output.txt'

def is_blocked(path):
    for blocked in blocked_dirs:
        if blocked in path.split(os.sep):
            return True
    return False

def is_file_blocked(file_name):
    return file_name in blocked_files

with open(output_file, 'w', encoding='utf-8') as out_file:
    for root, dirs, files in os.walk(start_path):
        if is_blocked(root):
            continue

        for file in files:
            if is_file_blocked(file):
                continue

            file_path = os.path.join(root, file)
            rel_path = os.path.relpath(file_path, start=start_path)

            # Sprawdzanie rozszerzenia
            _, ext = os.path.splitext(file)
            if ext in allowed_extensions:
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        content = f.read()

                    out_file.write(f'{rel_path}\n\n\n{content}\n\n\n')

                except Exception as e:
                    print(f'Błąd przy odczycie pliku {rel_path}: {e}')

print('Dump zakończony.')
