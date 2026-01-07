import os

# Lista dozwolonych rozszerzeń
allowed_extensions = ['.dart']

# Lista zablokowanych katalogów
blocked_dirs = ['venv', '__pycache__', '.git', 'migrations']
#blocked_dirs = ['venv', '__pycache__', '.git', 'migrations', 'health' , 'sentences']
#blocked_dirs = ['venv', '__pycache__', '.git', 'migrations', 'health']

# Lista zablokowanych plików (pełne nazwy plików)
blocked_files = ['dump_output.txt', 'dump_project.py', '.gitignore', 'alembic.ini', '__init__.py']

# Ścieżka startowa (można zmienić na inny katalog)
start_path = './lib'

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
            # Usunięto linię z os.path.relpath, aby zachować pełną ścieżkę (wraz z ./lib)

            # Sprawdzanie rozszerzenia
            _, ext = os.path.splitext(file)
            if ext in allowed_extensions:
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        content = f.read()

                    # Zmiana formatowania zapisu
                    out_file.write(f'===============================\n')
                    out_file.write(f'Ścieżka do pliku: {file_path}\n\n')
                    out_file.write('Zawartość pliku:\n\n')
                    out_file.write(f'{content}\n\n\n')

                except Exception as e:
                    print(f'Błąd przy odczycie pliku {file_path}: {e}')

print('Dump zakończony.')
