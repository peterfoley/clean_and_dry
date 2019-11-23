test_that("bounding box gets padded", {
  orig_bb <- c(left=1,bottom=2,right=3,top=4)
  padded <- pad_bb(orig_bb)
  expectation <- c(
    left=0.9,
    bottom=1.9,
    right=3.1,
    top=4.1
  )
  testthat::expect_equal(padded, expectation)
})
