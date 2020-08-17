\d .ml

// Clustering Using REpresentative points (CURE)

// @kind function
// @category clust
// @fileoverview CURE algorithm
// @param data {float[][]} Points in `value flip` format
// @param df   {fn}        Distance function
// @param n    {long}      Number of representative points per cluster
// @param c    {float}     Compression factor for representative points
// @return     {table}     Dendrogram
clust.cure:{[data;df;n;c]
  if[not df in key clust.i.dd;clust.i.err.dd[]];
  clust.hcscc["f"$data;df;`cure;1;n;c;1b]
  }

// @kind function
// @category clust
// @fileoverview Hierarchical Clustering
// @param data {float[][]} Points in `value flip` format
// @param df   {fn}        Distance function
// @param lf   {fn}        Linkage function
// @return     {table}     Dendrogram
clust.hc:{[data;df;lf]
  // check distance and linkage functions
  if[not df in key clust.i.dd;clust.i.err.dd[]];
  if[not lf in key clust.i.ld;clust.i.err.ld[]];
  if[lf in`complete`average`ward;:clust.hccaw["f"$data;df;lf;2;1b]];
  if[lf in`single`centroid;:clust.hcscc["f"$data;df;lf;1;::;::;1b]];
  }

// @kind function
// @category clust
// @fileoverview Complete, Average, Ward (CAW) Linkage
// @param data  {float[][]}    Points in `value flip` format
// @param df    {fn}           Distance function
// @param lf    {fn}           Linkage function
// @param k     {long}         Number of clusters
// @param dgram {bool}         Generate dendrogram or not (1b/0b)
// @return      {table/long[]} Dendrogram or list of clusters
clust.hccaw:{[data;df;lf;k;dgram]
  // check distance function for ward
  if[(not df~`e2dist)&lf=`ward;clust.i.err.ward[]];
  // create initial cluster table
  t0:clust.i.initcaw[data;df];
  // create linkage matrix
  m:([]i1:`int$();i2:`int$();dist:`float$();n:`int$());
  // merge clusters based on chosen algorithm
  r:{[k;r]k<count distinct r[0]`clt}[k]clust.i.algocaw[data;df;lf]/(t0;m);
  // return dendrogram or list of clusters
  $[dgram;clust.i.upddgram[r 0;r 1];clust.i.reindex r[0]`clt]
  }

// @kind function
// @category clust
// @fileoverview Single, Centroid, Cure (SCC) Linkage
// @param data  {float[][]} Points in `value flip` format
// @param df    {fn}        Distance function
// @param lf    {fn}        Linkage function
// @param k     {long}      Number of clusters
// @param n     {long}      Number of representative points per cluster
// @param c     {float}     Compression factor for representative points
// @param dgram {bool}      Generate dendrogram or not (1b/0b)
// @return      {long[]}    List of clusters
clust.hcscc:{[data;df;lf;k;n;c;dgram]
  if[(not df in `edist`e2dist)&lf=`centroid;clust.i.err.centroid[]];
  clustinit:clust.i.initscc[data;df;k;n;c;dgram];
  r:(count[data 0]-k).[clust.i.algoscc[data;df;lf]]/clustinit;
  vres:select from r[1]where valid;
  $[dgram;
    clust.i.dgramidx last[r]0;
    @[;;:;]/[count[data 0]#0N;vres`points;til count vres]]
  }

// @kind function
// @category clust
// @fileoverview Convert dendrogram table to k clusters
// @param t    {table}  Dendrogram
// @param kval {long}   Number of clusters
// @return     {long[]} List of clusters
clust.hccutk:{[t;kval]
  k:kval-1;
  clust.i.cutdgram[t;k]
  }

// @kind function
// @category clust
// @fileoverview Convert dendrogram to clusters based on distance threshold
// @param t       {table}  Dendrogram
// @param dthresh {float}  Cutting distance threshold
// @return        {long[]} List of clusters
clust.hccutdist:{[t;dthresh]
  k:0|count[t]-exec first i from t where dist>dthresh;
  clust.i.cutdgram[t;k]
  }

// @kind function
// @category private
// @fileoverview Update dendrogram for CAW with final cluster of all the points
// @param t  {table}     Cluster table
// @param m  {float[][]} Linkage matrix
// @return   {float[][]} Updated linkage matrix
clust.i.upddgram:{[t;m]
  m,:value exec first clt,first nni,first nnd,count reppt from t where nnd=min nnd;
  m
  }

// @kind function
// @category private
// @fileoverview Initialize cluster table
// @param data {float[][]} Points in `value flip` format
// @param df   {fn}        Distance function
// @return     {table}     Distances, neighbors, clusters and representatives
clust.i.initcaw:{[data;df]
  // create table with distances and nearest neighhbors noted
  t:{[data;df;i]
    `nni`nnd!(d?m;m:min d:@[;i;:;0w]clust.i.dists[data;df;data;i])
	}[data;df]each til count data 0;
  // update each points cluster and representatives
  update clt:i,reppt:flip data from t
  }

// @kind function
// @category private
// @fileoverview CAW algo
// @param data {float[][]}         Points in `value flip` format
// @param df   {fn}                Distance function
// @param lf   {fn}                Linkage function
// @param l    {(table;float[][])} List with cluster table and linkage matrix
// @return     {(table;float[][])} Updated l
clust.i.algocaw:{[data;df;lf;l]
  t:l 0;m:l 1;
  // update linkage matrix
  m,:value exec first clt,first nni,first nnd,count reppt from t where nnd=min nnd;
  // merge closest clusters
  merge:distinct value first select clt,nni from t where nnd=min nnd;
  // add new cluster and reppt into table
  t:update clt:1+max t`clt,reppt:count[i]#enlist sum[reppt]%count[i] from t where clt in merge;
  // exec pts by cluster
  cpts:exec pts:data[;i],n:count i,last reppt by clt from t;
  // find points initially closest to new cluster points
  chks:exec distinct clt from t where nni in merge;
  // run specific algo and return updated table
  t:clust.i.hcupd[lf][cpts;df;lf]/[t;chks];
  // return updated table and matrix
  (t;m)
  }

// @kind function
// @category private
// @fileoverview Complete linkage
// @param cpts {float[][]} Points in each cluster
// @param df   {fn}        Distance function
// @param lf   {fn}        Linkage function
// @param t    {table}     Cluster table
// @param chk  {long[]}    Points to check
// @return     {table}     Updated cluster table
clust.i.hcupd.complete:{[cpts;df;lf;t;chk]
  // calculate cluster distances using complete method
  dsts:{[df;lf;x;y]
    clust.i.ld[lf]raze clust.i.dd[df]x[`pts]-\:'y`pts
    }[df;lf;cpts chk]each cpts _ chk;
  // find nearest neighbors
  nidx:dsts?ndst:min dsts;
  // update cluster table
  update nni:nidx,nnd:ndst from t where clt=chk
  }

// @kind function
// @category private
// @fileoverview Average linkage
// @param cpts {float[][]} Points in each cluster
// @param df   {fn}        Distance function
// @param lf   {fn}        Linkage function
// @param t    {table}     Cluster table
// @param chk  {long[]}    Points to check
// @return     {table}     Updated cluster table
clust.i.hcupd.average:clust.i.hcupd.complete

// @kind function
// @category private
// @fileoverview Ward linkage
// @param cpts {float[][]} Points in each cluster
// @param df   {fn}        Distance function
// @param lf   {fn}        Linkage function
// @param t    {table}     Cluster table
// @param chk  {long[]}    Points to check
// @return     {table}     Updated cluster table
clust.i.hcupd.ward:{[cpts;df;lf;t;chk]
 // calculate distances using ward method
 dsts:{[df;lf;x;y]
   2*clust.i.ld[lf][x`n;y`n]clust.i.dd[df]x[`reppt]-y`reppt
   }[df;lf;cpts chk]each cpts _ chk;
 // find nearest neighbors
 nidx:dsts?ndst:min dsts;
 // update cluster table and rep pts
 update nni:nidx,nnd:ndst from t where clt=chk}

// @kind function
// @category private
// @fileoverview Initialize SCC clusters
// @param data {float[][]}                 Points in `value flip` format
// @param df   {fn}                        Distance function
// @param k    {long}                      Number of clusters
// @param n    {long}                      Number of representative points per 
//   cluster
// @param c    {float}                     Compression factor for 
//   representative points
// @return     {(dict;long[];table;table)} Parameters, clusters, representative
//   points and the kdtree
clust.i.initscc:{[data;df;k;n;c;dgram]
  // build kdtree
  kdtree:clust.kd.newtree[data]1000&ceiling .01*nd:count data 0;
  // create distance table with closest clusters identified
  dists:update closestClust:closestPoint from{[kdtree;data;df;i]
    clust.kd.nn[kdtree;data;df;i;data[;i]]
    }[kdtree;data;df]each til nd;
  lidx:select raze idxs,self:self where count each idxs from kdtree where leaf;
  r2l:exec self idxs?til count i from lidx;
  // create cluster table 
  clusts:select clusti:i,clust:i,valid:1b,reppts:enlist each i,
                points:enlist each i,closestDist,closestClust from dists;
  // create table of representative points for each cluster
  reppts:select reppt:i,clust:i,leaf:r2l,closestDist,closestClust from dists;
  reppts:reppts,'flip(rpcols:`$"x",'string til count data)!data;
  // create list of important parameters to carry forward
  params:`k`n`c`rpcols!(k;n;c;rpcols);
  lnkmat:([]i1:`int$();i2:`int$();dist:`float$();n:`int$());
  // return as a list to be passed to algos
  (params;clusts;reppts;kdtree;(lnkmat;dgram))
  }

// @kind function
// @category private
// @fileoverview Representative points for Centroid linkage
// @param p {float[][]} Data points
// @return  {float[]}   Representative point
clust.i.centrep:{[p]
  enlist avg each p
  }

// @kind function
// @category private
// @fileoverview Representative points for CURE
// @param df {fn}        Distance function
// @param n  {long}      Number of representative points per cluster
// @param c  {float}     Compression factor for representative points
// @param p  {float[][]} List of data points
// @return   {float[][]} List of representative points
clust.i.curerep:{[df;n;c;p]
  rpts:1_first(n&count p 0).[{[df;rpts;p]
    i:imax min clust.i.dd[df]each p-/:neg[1|-1+count rpts]#rpts;
    rpts,:enlist p[;i];
    (rpts;.[p;(::;i);:;0n])
    }[df]]/(enlist avgpt:avg each p;p);
  (rpts*1-c)+\:c*avgpt
  }

// @kind function
// @category private
// @fileoverview Update initial dendrogram structure to show path of merges so
//   that the dendrogram can be plotted with scipy
// @param dgram {table} Dendrogram stucture produced using 
//   .ml.clust.hc[...;...;...;...;1b]
// @return      {table} Updated dendrogram
clust.i.dgramidx:{[dgram]
  // initial cluster indices, number of merges and loop counter
  cl:raze dgram`i1`i2;n:count dgram;i:0;
  // increment a cluster for every occurrence in the tree
  while[n>i+1;cl[where[cl=cl i]except i]:1+max cl;i+:1];
  // update dendrogram with new indices
  ![dgram;();0b;`i1`i2!n cut cl]
  }

// @kind function
// @category private
// @fileoverview Convert dendrogram table to clusters
// @param t {table}  Dendrogram table
// @param k {long}   Define splitting value in dendrogram table
// @return  {long[]} List of clusters
clust.i.cutdgram:{[t;k]
  // get index of cluster made at cutting point k
  idx:(2*cntt:count t)-k-1;
  // exclude any clusters made after point k
  exclt:i where idx>i:raze neg[k]#'allclt:t`i1`i2;
  // extract indices within clusters made until k, excluding any outliers
  nout:exclt except outliers:exclt where exclt<=cntt;
  clt:{last{count x 0}clust.i.extractclt[x;y]/(z;())}[allclt;cntt+1]each nout;
  // update points to the cluster they belong to
  @[;;:;]/[(1+cntt)#0N;clt,enlist each outliers;til k+1]
  }

// @kind function
// @category private
// @fileoverview Extract points within merged cluster
// @param clts {long[]} List of cluster indices
// @param cntt {long}   Count of dend table 
// @param inds {long[]} Index in list to search and indices points found within
//   that cluster
// @return     {long[]} Next index to search, and additional points found 
//   within cluster
clust.i.extractclt:{[clts;cntt;inds]
  // extract the points that were merged at this point
  mrgclt:raze clts[;inds[0]-cntt];
  // Store any single clts, break down clts more than single point
  (mrgclt where inext;inds[1],mrgclt where not inext:mrgclt>=cntt)
  }

// @kind function
// @category private
// @fileoverview SCC algo
// @param data   {float[][]}                     Points in `value flip` format
// @param df     {fn}                            Distance function
// @param lf     {fn}                            Linkage function
// @param params {dict}                          Parameters - k (no. clusts), n
//   (no. reppts per clust), reppts, kdtree
// @param clusts {table}                         Cluster table
// @param reppts {float[][]}                     Representative points and 
//   associated info
// @param kdtree {table}                         k-dimensional tree storing 
//   points and distances
// @return       {(dict;long[];float[][];table)} Parameters dict, clusters, 
//   representative points and kdtree tables
clust.i.algoscc:{[data;df;lf;params;clusts;reppts;kdtree;lnkmat]

  // merge closest clusters
  clust0:exec clust{x?min x}closestDist from clusts where valid;
  newmrg:clusts clust0,clust1:clusts[clust0]`closestClust;
  newmrg:update valid:10b,reppts:(raze reppts;0#0),points:(raze points;0#0)from newmrg;

  // make dendrogram if required
  if[lnkmat 1;
    m:lnkmat 0;
    m,:newmrg[`clusti],fnew[`closestDist],count(fnew:first newmrg)`points;
    lnkmat[0]:m];

  // keep track of old reppts
  oldrep:reppts newmrg[0]`reppts;
  // find reps in new cluster
  $[sgl:lf~`single;
    // for single new reps=old reps -> no new points calculated 
    newrep:select reppt,clust:clust0 from oldrep;
    // if centroid reps=avg, if cure=calc reps
   [newrep:flip params[`rpcols]!flip$[lf~`centroid;clust.i.centrep;clust.i.curerep[df;params`n;params`c]]data[;newmrg[0]`points];
    newrep:update clust:clust0,reppt:count[i]#newmrg[0]`reppts from newrep;
    // new rep leaves
    newrep[`leaf]:(clust.kd.findleaf[kdtree;;kdtree 0]each flip newrep params`rpcols)`self;
    newmrg[0;`reppts]:newrep`reppt;
    // delete old points from leaf and update new point to new rep leaf
    kdtree:.[kdtree;(oldrep`leaf;`idxs);except;oldrep`reppt];
    kdtree:.[kdtree;(newrep`leaf;`idxs);union ;newrep`reppt]]];
  // update clusters and reppts
  clusts:@[clusts;newmrg`clust;,;delete clust from newmrg];
  reppts:@[reppts;newrep`reppt;,;delete reppt from newrep];
 
  updrep:reppts newrep`reppt;
  // nneighbour to clust
  if[sgl;updrep:select from updrep where closestClust in newmrg`clust];
  updrep:updrep,'clust.kd.nn[kdtree;reppts params`rpcols;df;newmrg[0]`points]each flip updrep params`rpcols;
  updrep:update closestClust:reppts[closestPoint;`clust]from updrep;

  if[sgl;
    reppts:@[reppts;updrep`reppt;,;select closestDist,closestClust from updrep];
    updrep:reppts newrep`reppt];
  // update nneighbour of new clust  
  updrep@:raze imin updrep`closestDist;
  clusts:@[clusts;updrep`clust;,;`closestDist`closestClust#updrep];

  $[sgl;
    // single - nneighbour=new clust
   [clusts:update closestClust:clust0 from clusts where valid,closestClust=clust1;
    reppts:update closestClust:clust0 from reppts where       closestClust=clust1];
    // else do nneighbour search
    if[count updcls:select from clusts where valid,closestClust in(clust0;clust1);
    updcls:updcls,'{x imin x`closestDist}each clust.kd.nn[kdtree;reppts params`rpcols;df]/:'
      [updcls`reppts;flip each reppts[updcls`reppts]@\:params`rpcols];
    updcls[`closestClust]:reppts[updcls`closestPoint]`clust;
    clusts:@[clusts;updcls`clust;,;select closestDist,closestClust from updcls]]];

  (params;clusts;reppts;kdtree;lnkmat)

  }
