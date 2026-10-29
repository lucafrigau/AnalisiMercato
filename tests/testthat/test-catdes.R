# Smoke test della Caratterizzazione (catdes/condes via FactoMineR).

test_that("catdes gira con cluster factor + descrittori misti", {
  set.seed(2)
  hc1 <- hclust(dist(iris[, 1:4]), method = "ward.D2")
  df <- iris
  df$cluster <- factor(cutree(hc1, k = 3))
  results <- catdes(
    data = df,
    vartochar = "cluster",
    descbyvar = c("Sepal.Length", "Sepal.Width", "Petal.Length", "Species")
  )
  expect_s3_class(results, "Group")
})

test_that("condes gira quando la variabile target è numerica", {
  df <- iris
  df$target <- iris$Sepal.Length  # numerica → triggera condes
  results <- catdes(
    data = df,
    vartochar = "target",
    descbyvar = c("Sepal.Width", "Petal.Length", "Species")
  )
  expect_s3_class(results, "Group")
})

test_that("catdes rifiuta una variabile target con un solo livello", {
  df <- iris
  df$cluster <- factor(rep("A", nrow(df)))
  expect_error(
    catdes(
      data = df,
      vartochar = "cluster",
      descbyvar = c("Sepal.Length")
    ),
    "almeno 2 livelli|at least 2 levels"
  )
})

# --- Regressioni 2.0.3 ---

test_that("catdes gestisce un livello inutilizzato del fattore Cluster (reg. 2.0.3)", {
  # FactoMineR fa droplevels() internamente: in 2.0.2 l'indicizzazione
  # posizionale produceva "subscript out of bounds".
  dd <- iris
  dd$cl <- factor(cutree(hclust(dist(iris[, 1:4]), "ward.D2"), 3),
                  levels = c("1", "2", "3", "4"))  # "4" vuoto
  expect_s3_class(
    catdes(data = dd, vartochar = "cl",
           descbyvar = c("Sepal.Length", "Species")),
    "Group"
  )
})

test_that("catdes: Eta² significativo senza v-test per-cluster non crasha (reg. 2.0.3)", {
  set.seed(303)
  d <- data.frame(
    cl = factor(rep(1:8, each = 6)),
    y  = rnorm(48)
  )
  d$y <- d$y + as.numeric(d$cl) * 0.15
  expect_s3_class(
    catdes(data = d, vartochar = "cl", descbyvar = "y", threshold = 5),
    "Group"
  )
})

test_that("catdes accetta un target character via interfaccia R (reg. 2.0.3)", {
  d <- data.frame(cl = rep(c("a", "b", "c"), each = 20),
                  y = rnorm(60), stringsAsFactors = FALSE)
  expect_s3_class(
    catdes(data = d, vartochar = "cl", descbyvar = "y"),
    "Group"
  )
})
