words = []
count = 0

with open ("sorted.txt","r") as f:
    # Get a list of lines in the file and covert it into a set
    words = f.readlines()
    count = len(words) 

words = set(words)
words = list(words)
words.sort()

with open('sorted2.txt', 'w') as f:
    for l in words:
        f.write(l)

print(count)
