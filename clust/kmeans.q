\d .ml

// K-Means

// @kind function
// @category clust
// @fileoverview K-Means algorithm
// @param data {float[][]} Points in `value flip` format
// @param df   {fn}        Distance function
// @param k    {long}      Number of clusters
// @param iter {long}      Number of iterations
// @param kpp  {bool}      Use kmeans++ or random initialization (1/0b)
// @return     {long[]}    List of clusters
clust.kmeans:{[data;df;k;iter;kpp]
  // check distance function
  if[not df in`e2dist`edist;clust.i.err.kmeans[]];
  // initialize representative points
  reppts0:$[kpp;clust.i.initkpp df;clust.i.initrdm][data;k];
  // run algo `iter` times
  reppts1:iter{[data;df;reppt]
    {[data;j]
      avg each data[;j]
      }[data]each value group clust.i.getclust[data;df;reppt]
    }[data;df]/reppts0;
  // return list of clusters
  clust.i.getclust[data;df;reppts1]
  }

// @kind function
// @category private
// @fileoverview Calculate final representative points
// @param data   {float[][]} Points in `value flip` format
// @param df     {fn}        Distance function
// @param reppts {float[]}   Representative points of each cluster
// @return       {long}      List of clusters
clust.i.getclust:{[data;df;reppts]
  dist:{[data;df;reppt]clust.i.dd[df]reppt-data}[data;df]each reppts;
  max til[count dist]*dist=\:min dist
  }

// @kind function
// @category private
// @fileoverview Random initialization of representative points
// @param data {float[][]} Points in `value flip` format
// @param k    {long}      Number of clusters
// @return     {float[][]} k representative points
clust.i.initrdm:{[data;k]
  flip data[;neg[k]?count data 0]
  }

// @kind function
// @category private
// @fileoverview K-Means++ initialization of representative points
// @param df   {fn}        Distance function
// @param data {float[][]} Points in `value flip` format
// @param k    {long}      Number of clusters
// @return     {float[][]} k representative points
clust.i.initkpp:{[df;data;k]
  info0:`point`dists!(data[;rand count data 0];0w);
  infos:(k-1)clust.i.kpp[data;df]\info0;
  infos`point
  }

// @kind function
// @category private
// @fileoverview K-Means++ algorithm
// @param data {float[][]} Points in `value flip` format
// @param df   {fn}        Distance function
// @param info {dict}      Points and distance info
// @return     {dict}      Updated info dictionary
clust.i.kpp:{[data;df;info]
  s:sums info[`dists]&:clust.i.dists[data;df;info`point;::];
  @[info;`point;:;data[;s binr rand last s]]
  }
