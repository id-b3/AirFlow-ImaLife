import matplotlib.pyplot as plt


def save_pi10_figure(x, y, model, pi10):

    fig, ax = plt.subplots()
    ax.scatter(x, y, alpha=0.5)
    ax.plot(x, model.predict(x), alpha=0.7, color='red', linewidth=2)
    ax.vlines(x=10, ymin=0, ymax=pi10, linestyles='--', colors='black', alpha=0.5)
    ax.hlines(y=pi10, xmin=0, xmax=10, linestyles='--', colors='black', alpha=0.5)

    # these are matplotlib.patch.Patch properties
    props = dict(boxstyle='round', facecolor='wheat', alpha=0.5)
    text = f"$R^{2}$ = {model.score(x, y):.3f}\nPi10 = {pi10[0]:.3f}"
    ax.text(0.05, 0.95, text, transform=ax.transAxes, fontsize=14,
            verticalalignment='top', bbox=props)
    ax.grid()
    ax.set_xlabel("Internal Perimeter")
    ax.set_ylabel("Square Root of Wall Area")
    ax.set_title("Pi10")

    # plt.xticks(())
    # plt.yticks(())

    plt.xlim([2.5, 18])
    plt.ylim([2.5, 7])
    plt.tight_layout()
    plt.savefig(f'pi10_{pi10[0]:.3f}.png', bbox_inches='tight', dpi=600)

    plt.show()
