# Kernel Density Estimation: Kernels and Methods

This document provides an overview of the different kernel functions and bandwidth selection methods available for kernel density estimation.

## 1. Kernel Functions

A kernel function is a symmetric function that integrates to one. It is used to weight the contribution of each data point to the density estimate at a given evaluation point. The choice of kernel function can affect the smoothness and accuracy of the density estimate.

### 1.1 Gaussian Kernel

The Gaussian kernel is the standard normal probability density function.

```
K(x) = (1/√(2π)) * exp(-x²/2)
```

**Characteristics:**
- Smooth and infinitely differentiable
- Has infinite support (non-zero everywhere)
- Most commonly used kernel
- Optimal for normally distributed data

**Usage:**
```powershell
Get-KernelDensityEstimateBasic -Data $data -KernelType Gaussian
```

### 1.2 Epanechnikov Kernel

The Epanechnikov kernel is optimal in terms of minimizing the mean integrated squared error.

```
K(x) = (3/4) * (1 - x²) for |x| ≤ 1, 0 otherwise
```

**Characteristics:**
- Has finite support (zero outside [-1, 1])
- Optimal in terms of efficiency
- Less smooth than Gaussian
- Good balance between computational efficiency and statistical efficiency

**Usage:**
```powershell
Get-KernelDensityEstimate -Data $data -KernelType Epanechnikov
```

### 1.3 Triangular Kernel

The triangular kernel is a simple kernel with a triangular shape.

```
K(x) = (1 - |x|) for |x| ≤ 1, 0 otherwise
```

**Characteristics:**
- Has finite support (zero outside [-1, 1])
- Simple to compute
- Less smooth than Gaussian and Epanechnikov
- Good for quick exploratory analysis

**Usage:**
```powershell
Get-KernelDensityEstimate -Data $data -KernelType Triangular
```

### 1.4 Uniform Kernel (Rectangular)

The uniform kernel gives equal weight to all points within a fixed distance.

```
K(x) = 0.5 for |x| ≤ 1, 0 otherwise
```

**Characteristics:**
- Has finite support (zero outside [-1, 1])
- Simplest kernel
- Results in a non-smooth density estimate
- Useful for understanding the basic concept of kernel density estimation

**Usage:**
```powershell
Get-KernelDensityEstimate -Data $data -KernelType Uniform
```

### 1.5 Biweight Kernel (Quartic)

The biweight kernel is a higher-order kernel that provides a smoother estimate than the Epanechnikov kernel.

```
K(x) = (15/16) * (1 - x²)² for |x| ≤ 1, 0 otherwise
```

**Characteristics:**
- Has finite support (zero outside [-1, 1])
- Smoother than Epanechnikov
- Good for data with complex structures
- Computationally more intensive than simpler kernels

**Usage:**
```powershell
Get-KernelDensityEstimate -Data $data -KernelType Biweight
```

### 1.6 Triweight Kernel

The triweight kernel is a higher-order kernel that provides an even smoother estimate than the biweight kernel.

```
K(x) = (35/32) * (1 - x²)³ for |x| ≤ 1, 0 otherwise
```

**Characteristics:**
- Has finite support (zero outside [-1, 1])
- Very smooth
- Good for data with very complex structures
- Computationally more intensive than simpler kernels

**Usage:**
```powershell
Get-KernelDensityEstimate -Data $data -KernelType Triweight
```

### 1.7 Cosine Kernel

The cosine kernel uses a cosine function to weight the data points.

```
K(x) = (π/4) * cos(πx/2) for |x| ≤ 1, 0 otherwise
```

**Characteristics:**
- Has finite support (zero outside [-1, 1])
- Smooth and differentiable
- Good alternative to Gaussian for data with bounded support
- Computationally efficient

**Usage:**
```powershell
Get-KernelDensityEstimate -Data $data -KernelType Cosine
```

### 1.8 Optimal Kernel Selection

The optimal kernel depends on the characteristics of the data and the specific application. In practice, the choice of kernel often has less impact on the quality of the density estimate than the choice of bandwidth.

The `OptimalKernel` option automatically selects the most appropriate kernel based on the data characteristics.

```powershell
Get-KernelDensityEstimate -Data $data -KernelType OptimalKernel
```

## 2. Bandwidth Selection Methods

The bandwidth is a smoothing parameter that controls the width of the kernel function. It determines the trade-off between bias and variance in the density estimate. A larger bandwidth results in a smoother estimate but may obscure important features of the data, while a smaller bandwidth can reveal more detail but may introduce noise.

### 2.1 Silverman's Rule of Thumb

Silverman's rule of thumb is a simple and widely used method for bandwidth selection. It assumes that the underlying density is Gaussian.

```
h = 0.9 * min(σ, IQR/1.34) * n^(-1/5)
```

where:
- σ is the standard deviation of the data
- IQR is the interquartile range
- n is the number of data points

**Characteristics:**
- Simple and fast
- Works well for unimodal, roughly symmetric distributions
- May oversmooth multimodal distributions
- Good default choice for exploratory analysis

**Usage:**
```powershell
Get-KernelDensityEstimate -Data $data -Method Silverman
```

### 2.2 Scott's Rule

Scott's rule is similar to Silverman's rule but uses a different constant.

```
h = 1.06 * σ * n^(-1/5)
```

**Characteristics:**
- Simple and fast
- Works well for unimodal, roughly symmetric distributions
- May oversmooth multimodal distributions
- Good alternative to Silverman's rule

**Usage:**
```powershell
Get-KernelDensityEstimate -Data $data -Method Scott
```

### 2.3 Leave-One-Out Cross-Validation

Leave-one-out cross-validation selects the bandwidth that minimizes the integrated squared error between the density estimate and the true density.

**Characteristics:**
- Data-driven approach
- Does not assume a specific distribution
- Computationally intensive
- Can undersmooth the data

**Usage:**
```powershell
Get-KernelDensityEstimate -Data $data -Method LeaveOneOut
```

### 2.4 K-Fold Cross-Validation

K-fold cross-validation divides the data into K subsets and uses each subset as a validation set.

**Characteristics:**
- Data-driven approach
- Less computationally intensive than leave-one-out
- More stable than leave-one-out
- Good balance between computational efficiency and statistical efficiency

**Usage:**
```powershell
Get-KernelDensityEstimate -Data $data -Method KFold -KFolds 5
```

### 2.5 Optimized Cross-Validation

Optimized cross-validation uses numerical optimization to find the bandwidth that minimizes a specific criterion.

**Characteristics:**
- Data-driven approach
- Can be tailored to specific objectives
- Computationally intensive
- Can provide the most accurate bandwidth for complex distributions

**Usage:**
```powershell
Get-KernelDensityEstimate -Data $data -Method Optimized -Objective Accuracy
```

### 2.6 Automatic Selection

The `Auto` method automatically selects the most appropriate bandwidth selection method based on the data characteristics.

```powershell
Get-KernelDensityEstimate -Data $data -Method Auto
```

## 3. Objectives for Bandwidth Selection

When using optimized cross-validation or the automatic selection method, you can specify an objective to prioritize.

### 3.1 Accuracy

Prioritizes the accuracy of the density estimate, even at the cost of computational efficiency.

```powershell
Get-KernelDensityEstimate -Data $data -Method Optimized -Objective Accuracy
```

### 3.2 Speed

Prioritizes computational speed, even at the cost of some accuracy.

```powershell
Get-KernelDensityEstimate -Data $data -Method Optimized -Objective Speed
```

### 3.3 Robustness

Prioritizes robustness to outliers and unusual data patterns.

```powershell
Get-KernelDensityEstimate -Data $data -Method Optimized -Objective Robustness
```

### 3.4 Adaptability

Prioritizes adaptability to different types of distributions.

```powershell
Get-KernelDensityEstimate -Data $data -Method Optimized -Objective Adaptability
```

### 3.5 Balanced

Balances all objectives for a good overall performance.

```powershell
Get-KernelDensityEstimate -Data $data -Method Optimized -Objective Balanced
```

## 4. Recommendations

### 4.1 For Exploratory Analysis

- Kernel: Gaussian or Epanechnikov
- Method: Silverman or Auto
- Objective: Balanced

### 4.2 For Accurate Density Estimation

- Kernel: Gaussian, Epanechnikov, or OptimalKernel
- Method: KFold or Optimized
- Objective: Accuracy

### 4.3 For Fast Computation

- Kernel: Uniform or Triangular
- Method: Silverman or Scott
- Objective: Speed

### 4.4 For Complex Distributions

- Kernel: Biweight, Triweight, or OptimalKernel
- Method: KFold or Optimized
- Objective: Adaptability

### 4.5 For Data with Outliers

- Kernel: Epanechnikov or Biweight
- Method: KFold or Optimized
- Objective: Robustness

## 5. References

- Silverman, B. W. (1986). Density Estimation for Statistics and Data Analysis. Chapman & Hall/CRC.
- Scott, D. W. (2015). Multivariate Density Estimation: Theory, Practice, and Visualization. John Wiley & Sons.
- Wand, M. P., & Jones, M. C. (1994). Kernel Smoothing. Chapman & Hall/CRC.
- Härdle, W., Müller, M., Sperlich, S., & Werwatz, A. (2004). Nonparametric and Semiparametric Models. Springer.
