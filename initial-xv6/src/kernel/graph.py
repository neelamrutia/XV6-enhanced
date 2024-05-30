import matplotlib.pyplot as plt
import numpy as np

data = np.loadtxt('test.txt', dtype=int)

array_of_pids = {}
for pid, ticks, que_no in data:
    if pid not in array_of_pids:
        array_of_pids[pid] = {'ticks': [], 'queue': []}
    array_of_pids[pid]['queue'].append(que_no)
    array_of_pids[pid]['ticks'].append(ticks)

plt.figure(figsize=(10, 6))

for pid, pid_data in array_of_pids.items():
    plt.plot(pid_data['ticks'], pid_data['queue'], label=f'PID {pid}')

plt.xlabel('ticks')
plt.ylabel('queue No')
plt.title('queue No vs. ticks for different PIDs')
plt.legend()
plt.grid(True)

plt.tight_layout()
plt.show()
