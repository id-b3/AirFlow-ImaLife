import optuna


def objective(trial):
    x = trial.suggest_uniform('x', 0, 100)
    y = trial.suggest_uniform('y', -10, 10)
    z = trial.suggest_uniform('z', -3, 10)
    return (x ** z - 3 * y * 2) ** 2


study = optuna.create_study()

study.optimize(objective, n_trials=1000)
print(study.best_params)



