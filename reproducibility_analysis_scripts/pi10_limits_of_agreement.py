import pingouin as pg
import matplotlib.pyplot as plt
import statsmodels as sm
import pandas as pd
import numpy as np
import seaborn as sns
from sklearn import metrics


def plot_loa(x, y):
    r2 = metrics.r2_score(x, y)

    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(8, 5))

    # sm.graphics.mean_diff_plot(x, y, ax=ax)
    # plt.savefig(str(Path(outdir / f"bland_altmann_pi10.jpg").resolve()), dpi=300)
    ping_fig = pg.plot_blandaltman(x, y, figsize=(8, 5), ax=ax1)
    sns.regplot(x, y, ax=ax2)
    props = dict(boxstyle="round", facecolor="wheat", alpha=0.5)
    text = f"$R^{2}$ = {r2:.3f}"
    ax2.text(
        0.05,
        0.95,
        text,
        transform=ax2.transAxes,
        fontsize=14,
        verticalalignment="top",
        bbox=props,
    )
    fig.tight_layout()
    fig.show()


def bland_altman_analysis(df):
    """Calculate agreement statistics."""
    tests = list(df)

    # Individual sample calculations
    df["Mean"] = df[tests].mean(axis=1)
    df["Diff"] = df[tests].diff(axis=1)[tests[-1]]
    df["SD"] = df[tests].std(axis=1, ddof=1)
    df["Variance"] = df["SD"] ** 2

    # Whole sample calculations
    summary = pd.DataFrame()
    means = ["Mean of " + test for test in tests]
    for i, mean in enumerate(means):
        summary.loc[1, mean] = df[tests[i]].mean()
    # Sample size
    summary.loc[1, "N"] = df.shape[0]
    # Degrees of freedom
    summary.loc[1, "DoF"] = df.shape[0] - 1
    # Bias (mean difference)
    mean_diff = df["Diff"].mean()
    summary.loc[1, "Mean Diff (Bias)"] = mean_diff
    # Standard deviation of the differences
    st_dev_diff = df["Diff"].std(ddof=0)
    summary.loc[1, "SD Diffs"] = st_dev_diff
    summary.loc[1, "Lower LoA"] = mean_diff - 1.96 * st_dev_diff
    summary.loc[1, "Upper LoA"] = mean_diff + 1.96 * st_dev_diff
    # Within-subject standard deviation
    s_w = np.sqrt(df["Variance"].mean())
    summary.loc[1, "Within-Subject SD (Sw)"] = s_w
    # Coefficient of repeatability
    col = "Repeatability Coefficient (RC)"
    summary.loc[1, col] = np.sqrt(2) * 1.96 * s_w

    # Return
    return df, summary


# in_pi10 = "D:\\Repeat_Scans_Experiments\\summary_files\\pi10\\results_pi10.csv"
in_pi10 = "/media/ivan/T7 Touch1/Repeat_Scans_Experiments/summary/luvar_860_pi10/results_pi10_10.csv"
df = pd.read_csv(in_pi10)
print(df.head())
result, summary = bland_altman_analysis(df[["Pi10_first", "Pi10_repeat"]])
print(summary)
fig_p = pg.plot_blandaltman(df.Pi10_first, df.Pi10_repeat, figsize=(5, 8))
plt.tight_layout()
plt.show()
fig_r = sns.regplot(df.Pi10_first, df.Pi10_repeat)
r2 = metrics.r2_score(df.Pi10_first, df.Pi10_repeat)
print(f"R2 is {r2}")
plt.show()
# plot_loa(df.Pi10_first, df.Pi10_repeat)
