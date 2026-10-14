function [posteriorMean,posteriorMeanCovariance,diagnostics] = ...
    blackLittermanPosterior(priorMean,covariance,tau, ...
    viewMatrix,viewReturns,viewCovariance)
%BLACKLITTERMANPOSTERIOR Combine an equilibrium prior with uncertain views.
%   [MU,CMU,D] = BLACKLITTERMANPOSTERIOR(PI,SIGMA,TAU,P,Q,OMEGA)
%   returns the Black--Litterman posterior mean MU and the posterior
%   covariance CMU of the uncertain mean. PI may be a row or column vector;
%   MU is returned as a row vector. SIGMA remains the return covariance and
%   is not silently replaced by CMU in downstream portfolio construction.
%
%   The model is
%
%       mu ~ N(PI,tau*SIGMA),       P*mu ~ N(Q,OMEGA).
%
%   Linear systems are used throughout; no explicit matrix inverse is
%   formed.
%
% SPDX-License-Identifier: BSD-3-Clause

priorMeanColumn = priorMean(:);
numberOfAssets = numel(priorMeanColumn);

if ~ismatrix(covariance) || ...
        ~isequal(size(covariance),[numberOfAssets numberOfAssets])
    error('STA4028Z:BlackLittermanCovarianceSize', ...
        'The return covariance must be square and match the prior mean.');
end
if ~isscalar(tau) || ~isfinite(tau) || tau <= 0
    error('STA4028Z:BlackLittermanTau', ...
        'tau must be a finite positive scalar.');
end
if size(viewMatrix,2) ~= numberOfAssets
    error('STA4028Z:BlackLittermanViewMatrixSize', ...
        'The view matrix must have one column for each asset.');
end

numberOfViews = size(viewMatrix,1);
viewReturnsColumn = viewReturns(:);
if numel(viewReturnsColumn) ~= numberOfViews
    error('STA4028Z:BlackLittermanViewReturnSize', ...
        'The view-return vector must have one entry for each view.');
end
if ~isequal(size(viewCovariance),[numberOfViews numberOfViews])
    error('STA4028Z:BlackLittermanViewCovarianceSize', ...
        'The view covariance must be square with one row per view.');
end

covariance = (covariance+covariance')/2;
viewCovariance = (viewCovariance+viewCovariance')/2;
priorMeanCovariance = tau*covariance;

if numberOfViews == 0
    posteriorMeanColumn = priorMeanColumn;
    posteriorMeanCovariance = priorMeanCovariance;
    diagnostics = struct( ...
        'PriorView',zeros(0,1), ...
        'ViewInnovation',zeros(0,1), ...
        'InnovationCovariance',zeros(0,0), ...
        'InnovationReciprocalCondition',NaN);
    posteriorMean = posteriorMeanColumn';
    return
end

innovationCovariance = viewMatrix*priorMeanCovariance*viewMatrix' + ...
    viewCovariance;
innovationCovariance = ...
    (innovationCovariance+innovationCovariance')/2;
if rcond(innovationCovariance) <= eps
    error('STA4028Z:BlackLittermanSingularViews', ...
        'The combined view-innovation covariance is singular.');
end

priorView = viewMatrix*priorMeanColumn;
viewInnovation = viewReturnsColumn-priorView;
viewAdjustment = priorMeanCovariance*viewMatrix' * ...
    (innovationCovariance\viewInnovation);
posteriorMeanColumn = priorMeanColumn+viewAdjustment;

posteriorMeanCovariance = priorMeanCovariance - ...
    priorMeanCovariance*viewMatrix' * ...
    (innovationCovariance\(viewMatrix*priorMeanCovariance));
posteriorMeanCovariance = ...
    (posteriorMeanCovariance+posteriorMeanCovariance')/2;
posteriorMean = posteriorMeanColumn';

diagnostics = struct( ...
    'PriorView',priorView, ...
    'ViewInnovation',viewInnovation, ...
    'InnovationCovariance',innovationCovariance, ...
    'InnovationReciprocalCondition',rcond(innovationCovariance));
end
