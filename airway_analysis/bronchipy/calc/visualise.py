import matplotlib.pyplot as plt
from pathlib import Path


def save_pi10_figure(x, y, model, pi10, name, savedir: str, show=False):

    fig, ax = plt.subplots()
    ax.scatter(x, y, alpha=0.5)
    # ax.plot(x, model.predict(x), alpha=0.7, color='red', linewidth=2)
    ax.axline(
        (0, model.intercept_), slope=model.coef_[0], alpha=0.7, color="red", linewidth=2
    )
    ax.vlines(x=10, ymin=0, ymax=pi10, linestyles="--", colors="black", alpha=0.5)
    ax.hlines(y=pi10, xmin=0, xmax=10, linestyles="--", colors="black", alpha=0.5)

    # these are matplotlib.patch.Patch properties
    props = dict(boxstyle="round", facecolor="wheat", alpha=0.5)
    text = f"$R^{2}$ = {model.score(x, y):.3f}\nPi10 = {pi10[0]:.3f}"
    ax.text(
        0.05,
        0.95,
        text,
        transform=ax.transAxes,
        fontsize=14,
        verticalalignment="top",
        bbox=props,
    )
    ax.grid()
    ax.set_xlabel("Internal Perimeter")
    ax.set_ylabel("Square Root of Wall Area")
    ax.set_title("Pi10")

    plt.xlim([5, 25])
    plt.ylim([2.5, 5.5])
    plt.tight_layout()

    savedir = Path(savedir)
    savedir.mkdir(parents=True, exist_ok=True)
    # savepath = savedir / f"pi10_{name}_{pi10[0]:.3f}.png"
    savepath = savedir / f"{name}.jpg"
    print(savepath)
    plt.savefig(savepath, bbox_inches="tight", dpi=600)

    if show:
        plt.show()
