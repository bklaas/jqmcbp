from sys import argv

def slurpNbarf(input_file, encoding, convert=False):
    words = []
    with open(input_file, "r", encoding=encoding) as f:
        for line in f.readlines():
            if convert:
                line = line.decode()
                
            words.append(line.strip())
    return words

input_file = argv[1]

try:
    words = slurpNbarf(input_file, "utf-8")
except UnicodeDecodeError:
    words = slurpNbarf(input_file, "cp1252")

[print(word) for word in words]

