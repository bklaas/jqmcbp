from pathlib import Path
from sys import argv

def slurpNbarf(input_file, encoding, convert=False):
    words = []
    with open(input_file, "r", encoding=encoding) as f:
        for line in f.readlines():
            if convert:
                line = line.decode()
                
            words.append(line.strip())
    return words


def fix_file(input_file, output_file):
    try:
        words = slurpNbarf(input_file, "utf-8")
    except UnicodeDecodeError:
        words = slurpNbarf(input_file, "cp1252")
    finally:
        print(f"Writing fix to: {output_file}")
        with open(output_file, "w") as f:
            for word in words:
                f.write(f"{word}\n")

bad = argv[1]
good = argv[2]

print(bad, good)

# Define the directory
dir_path = Path(bad)
output_dir = Path(good)
output_dir.mkdir(parents=True, exist_ok=True)
output_dir.chmod(0o777)

# Create a list of Path objects for all .dat files in the directory
dat_files = list(dir_path.glob('*.dat'))

for dat_file in dat_files:
    output_file = output_dir/dat_file.name
    fix_file(dat_file, output_file)


