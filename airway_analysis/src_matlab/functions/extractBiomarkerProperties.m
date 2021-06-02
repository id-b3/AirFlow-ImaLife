function results = extractBiomarkerProperties( vData, vWeights )

       results.mean = nanmean( vData );
       results.median = nanmedian( vData );
%        results.weightedMean = weightedMean( vData, vWeights );
%        results.weightedMedian = weigthedQuantiles( vectorData, vWeights, 0.5 );
       results.values = vData;
end

function wm = weightedMean ( v, w )
    wm = sum( v .* w ) / sum(w);
end

function wm = weigthedQuantiles ( v, w, q )
    % weights have to be positive
    if sum(w < 0)
        error('Weighted Quantiles only work with positives weights');
    end

    % sort values
    [vSorted, idSorted] = sort(v, 'ascend');
    
    % define threshold by weight according to percentiles (e.g., q = 0.5 for medain)
    thresholds = q .* sum(w);
    
    % keep track of comptued quantiles
    computedQuantile = false(size(q));

    weightSum = 0;
    for ii = idSorted
        weightSum = weightSum + w(ii);
        
        % check if a threshold has been crossed
        for jj = 1:numel(thresholds)
            if ~computedQuantile(jj) && weightSum >= thresholds(jj)
               wm(jj) = v(ii);
               computedQuantile(jj) = true;
            end
        end
    end
    
end