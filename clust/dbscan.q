\d .ml

// Density-Based Spatial Clustering of Applications with Noise (DBSCAN)

// @kind function
// @category clust
// @fileoverview DBSCAN algorithm
// @param data   {float[][]} Points in `value flip` format
// @param df     {fn}        Distance function
// @param minpts {long}      Minimum number of points in epsilon radius
// @param eps    {float}     Epsilon radius to search
// @return       {long[]}    List of clusters
clust.dbscan:{[data;df;minpts;eps]
 // check distance function
 if[not df in key clust.i.dd;clust.i.err.dd[]];
 // calculate distances and find all points which are not outliers
 nbhood:clust.i.nbhood["f"$data;df;eps]each til count data 0;
 // update outlier cluster to null
 t:update cluster:0N,corepoint:minpts<=1+count each nbhood from([]nbhood);
 // find cluster for remaining points and return list of clusters
 exec cluster from {[t]any t`corepoint}clust.i.dbalgo/t}

// @kind function
// @category private
// @fileoverview Find all points which are not outliers
// @param data {float[][]} Points in `value flip` format
// @param df   {fn}        Distance function
// @param eps  {float}     Epsilon radius to search
// @param idx  {long}      Index of current point
// @return     {long[]}    Indices of points within the epsilon radius
clust.i.nbhood:{[data;df;eps;idx]
  where eps>@[;idx;:;0w]clust.i.dd[df]data-data[;idx]
  }

// @kind function
// @category private
// @fileoverview Run DBSCAN algorithm and update cluster of each point
// @param t {table} Cluster info table
// @return  {table} Updated cluster table with old clusters merged
clust.i.dbalgo:{[t]
  nbh:.ml.clust.i.nbhoodidxs[t]/[first where t`corepoint];
  update cluster:0|1+max t`cluster,corepoint:0b from t where i in nbh
  }

// @kind function
// @category private
// @fileoverview Find indices in each points neighborhood
// @param t    {table}  Cluster info table
// @param idxs {long[]} Indices to search neighborhood of
// @return     {long[]} Indices in neighborhood
clust.i.nbhoodidxs:{[t;idxs]
  nbh:exec nbhood from t[distinct idxs,raze t[idxs]`nbhood]where corepoint;
  asc distinct idxs,raze nbh
  }
