#formula for CYCLE_WAIT = CLOCK_FREQUENCY*440/(8000*f) where f is the desired frequency
fundamental_notes = {
    440: "A", 466.16: "A#", 493.88: "B", 261.63: "C", 277.18: "C#",
    293.66: "D", 311.13: "D#", 329.63: "E", 349.23: "F", 369.99: "F#",
    392: "G", 415.3: "G#"
}
cycles = []
for freq in fundamental_notes.keys():
    cycles.append(round(200_000_000*440/(8000*freq)))
cycles_dict = {note:cycle for (cycle,note) in zip(cycles,fundamental_notes.values())}
print(cycles_dict)