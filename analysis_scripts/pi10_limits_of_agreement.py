import pingouin as pg
import matplotlib.pyplot as plt
import statsmodels as sm
import pandas as pd
import numpy as np


def bland_altman_analysis(df):
    """Calculate agreement statistics."""
    tests = list(df)

    # Individual sample calculations
    df['Mean'] = df[tests].mean(axis=1)
    df['Diff'] = df[tests].diff(axis=1)[tests[-1]]
    df['SD'] = df[tests].std(axis=1, ddof=1)
    df['Variance'] = df['SD']**2

    # Whole sample calculations
    summary = pd.DataFrame()
    means = ['Mean of ' + test for test in tests]
    for i, mean in enumerate(means):
        summary.loc[1, mean] = df[tests[i]].mean()
    # Sample size
    summary.loc[1, 'N'] = df.shape[0]
    # Degrees of freedom
    summary.loc[1, 'DoF'] = df.shape[0] - 1
    # Bias (mean difference)
    mean_diff = df['Diff'].mean()
    summary.loc[1, 'Mean Diff (Bias)'] = mean_diff
    # Standard deviation of the differences
    st_dev_diff = df['Diff'].std(ddof=0)
    summary.loc[1, 'SD Diffs'] = st_dev_diff
    summary.loc[1, 'Lower LoA'] = mean_diff - 1.96 * st_dev_diff
    summary.loc[1, 'Upper LoA'] = mean_diff + 1.96 * st_dev_diff
    # Within-subject standard deviation
    s_w = np.sqrt(df['Variance'].mean())
    summary.loc[1, 'Within-Subject SD (Sw)'] = s_w
    # Coefficient of repeatability
    col = 'Repeatability Coefficient (RC)'
    summary.loc[1, col] = np.sqrt(2) * 1.96 * s_w

    # Return
    return df, summary


in_pi10 = "D:\\Repeat_Scans_Experiments\\summary_files\\pi10\\results_pi10.csv"
df = pd.read_csv(in_pi10)
print(df.head())
result, summary = bland_altman_analysis(df[["Pi10_first", "Pi10_repeat"]])
print(summary)
fig_p = pg.plot_blandaltman(df.Pi10_first, df.Pi10_repeat, figsize=(5, 8))
plt.tight_layout()
plt.show()
