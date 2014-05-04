using MCMCsim
using Distributions

## Data
surgical = (String => Any)[
  "r" => [0, 18, 8, 46, 8, 13, 9, 31, 14, 8, 29, 24],
  "n" => [47, 148, 119, 810, 211, 196, 148, 215, 207, 97, 256, 360],
  "N" => 12
]


## Model Specification

model = MCMCModel(

  r = MCMCStochastic(1,
    @modelexpr(n, p, N,
      Distribution[Binomial(n[i], p[i]) for i in 1:N]
    ),
    false
  ),

  p = MCMCLogical(1,
    @modelexpr(b,
      1.0 / (exp(-b) + 1.0)
    )
  ),

  b = MCMCStochastic(1,
    @modelexpr(mu, N, s2,
      IsoNormal(mu * ones(N), sqrt(s2))
    ),
    false
  ),

  mu = MCMCStochastic(
    :(Normal(0.0, 1.0e6))
  ),

  pop_mean = MCMCLogical(
    @modelexpr(mu,
      1.0 / (exp(-mu) + 1.0)
    )
  ),

  s2 = MCMCStochastic(
    :(InverseGamma(0.001, 0.001))
  )

)


## Initial Values
inits = [
  ["r" => surgical["r"], "b" => fill(0.1, surgical["N"]), "s2" => 1, "mu" => 0],
  ["r" => surgical["r"], "b" => fill(0.5, surgical["N"]), "s2" => 10, "mu" => 1]
]


## Sampling Scheme
scheme = [SamplerNUTS(["b"]),
          SamplerSlice(["mu", "s2"], [1.0, 1.0])]
setsamplers!(model, scheme)


## MCMC Simulations
sim = mcmc(model, surgical, inits, 10000, burnin=2500, thin=2, chains=2)
describe(sim)