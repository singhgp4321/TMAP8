import glob
import os
import pandas as pd
import matplotlib.pyplot as plt

csv_dir = os.path.dirname(os.path.abspath(__file__))

# --- Line sampler data (temp, stress vs time at each radial position) ---
csv_files = sorted(glob.glob(os.path.join(csv_dir, '*_line_sample_*.csv')))

# Determine which stress columns are available
sample_df = pd.read_csv(csv_files[0])
stress_cols = [c for c in ['stress_xx', 'stress_yy', 'stress_zz'] if c in sample_df.columns]

data = {}
for f in csv_files:
    time = int(os.path.basename(f).split('_')[-1].replace('.csv', ''))
    df = pd.read_csv(f)
    for _, row in df.iterrows():
        x = row['x']
        if x not in data:
            data[x] = {'time': [], 'temp': []}
            for col in stress_cols:
                data[x][col] = []
        data[x]['time'].append(time)
        data[x]['temp'].append(row['temp'])
        for col in stress_cols:
            data[x][col].append(row[col])

# --- Dehydriding rate data ---
pp_file = os.path.join(csv_dir, 'cylinder_thermal_diffusion_mechanics_1D_matProp_csv.csv')
pp_df = pd.read_csv(pp_file)

# --- Plotting ---
n_stress = len(stress_cols)
n_plots = 2 + n_stress  # temp + stresses + dehydriding rate
fig, axes = plt.subplots(1, n_plots, figsize=(6 * n_plots, 5))

# Temperature
ax_temp = axes[0]
for x in sorted(data.keys()):
    label = f'r = {x * 1e3:.2f} mm'
    ax_temp.plot(data[x]['time'], data[x]['temp'], label=label)
ax_temp.set_xlabel('Time (s)')
ax_temp.set_ylabel('Temperature (K)')
ax_temp.set_title('Temperature')
ax_temp.legend()
ax_temp.grid(True)

# Stress components
stress_labels = {'stress_xx': 'Radial Stress (stress_xx)',
                 'stress_yy': 'Axial Stress (stress_yy)',
                 'stress_zz': 'Hoop Stress (stress_zz)'}
for i, col in enumerate(stress_cols):
    ax = axes[1 + i]
    for x in sorted(data.keys()):
        label = f'r = {x * 1e3:.2f} mm'
        ax.plot(data[x]['time'], [s * 1e-6 for s in data[x][col]], label=label)
    ax.set_xlabel('Time (s)')
    ax.set_ylabel('Stress (MPa)')
    ax.set_title(stress_labels.get(col, col))
    ax.legend()
    ax.grid(True)

# Dehydriding rate
ax_dh = axes[-1]
ax_dh.plot(pp_df['time'], pp_df['dehydriding_rate_total'], color='k')
ax_dh.set_xlabel('Time (s)')
ax_dh.set_ylabel('Dehydriding Rate (mol/s)')
ax_dh.set_title('Dehydriding Rate')
ax_dh.grid(True)

plt.tight_layout()
plt.savefig(os.path.join(csv_dir, 'results_plot.png'), dpi=150)
plt.show()
