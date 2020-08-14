\d .ml

// Cross Validation, Grid/Random/Sobol Hyperparameter Search and 
//  Multi-Processing Procedures

// Cross Validation

// @kind function
// @category private
// @fileoverview Shuffle data point indices
// @param data {#any}   Table, matrix or list
// @return     {long[]} Indices of data shuffled
xv.i.shuffle:{[data]
  0N?count data
  }

// @kind function
// @category private
// @fileoverview Find indices required to split data into k-folds
// @param k    {int}      Number of folds
// @param data {#any}     Table, matrix or list
// @return     {long[][]} Indices required to split data into k sub-sets
xv.i.splitidx:{[k;data]
  (k;0N)#til count data
  }

// @kind function
// @category private
// @fileoverview Find shuffled indices required to split data into k-folds
// @param k    {int}      Number of folds
// @param data {#any}     Table, matrix or list
// @return     {long[][]} Shuffled indices required to split data into k 
//   sub-sets
xv.i.shuffidx:{[k;data]
  (k;0N)#xv.i.shuffle data
  }

// @kind function
// @category private
// @fileoverview Split target data ensuring that each distinct value appears in
//   each fold
// @param k    {int}      Number of folds
// @param data {#any}     Table, matrix or list
// @return     {long[][]} Data split into k-folds with distinct values 
//   appearing in each
xv.i.stratidx:{[k;data]
  // find indices for each distinct group
  n:group data;
  // shuffle/split groups into folds with distinct groups present in each fold
  r:(,'/)(k;0N)#/:value n@'xv.i.shuffle each n;
  // shuffle each fold
  r@'xv.i.shuffle each r
  }

// @kind function
// @category private
// @fileoverview Get training and testing indices for each fold
// @param k {int}      Number of folds
// @return  {long[][]} Training and testing indices for each fold
xv.i.groupidx:{[k]
  (0;k-1)_/:rotate[-1]\[til k]
  }

// @kind function
// @category private
// @fileoverview Get training/testing indices for equi-distanced bins of data 
//   across k-folds
// @param k {int}      Number of folds
// @return  {long[][]} Indices for equi-distanced bins of data based on k
xv.i.tsrollsidx:{[k]
  enlist@''0 1+/:til k-1
  }

// @kind function
// @category private
// @fileoverview Get training/testing indices for equi-distanced bins of data 
//   across k-folds with increasing amounts of data added to the training set 
//   at each stage
// @param k {int}      Number of folds
// @return  {long[][]} Indices for equi-distanced bins of data based on k
xv.i.tschainidx:{[k]
  flip(til each j;enlist@'j:1+til k-1)
  }

// @kind function
// @category private
// @fileoverview Creates projection contining data split according to k
//   in ((xtrain;ytrain);(xtest;ytest)) format for each fold
// @param func1 {fn}       Function to be applied to x data
// @param func2 {fn}       Function to be applied to k
// @param k     {int}      Number of folds
// @param feat  {#any[][]} Matrix of features
// @param targ  {#any[]}   Vector of targets
// @return      {fn}       Projection of data split per fold
xv.i.idx1:{[func1;func2;k;feat;targ]
  {{raze@''y}[;x]}each flip@'((feat;targ)@/:\:func1[k;targ])@\:/:func2 k
  }

// @kind function
// @category private
// @fileoverview Creates projection contining data split according to k
//   in ((xtrain;ytrain);(xtest;ytest)) format for each fold
// @param func1 {fn}       Function to be applied to x data
// @param func2 {fn}       Function to be applied to k
// @param k     {int}      Number of folds
// @param n     {int}      Number of repetitions
// @param feat  {#any[][]} Matrix of features
// @param targ  {#any[]}   Vector of targets
// @return      {fn}       Projection of data split per fold
xv.i.idxR:{[func1;func2;k;n;feat;targ]
  n#enlist xv.i.idx1[func1;func2;k;feat;targ]
  }

// @kind function
// @category private
// @fileoverview Creates projection contining data split according to k
//   in ((xtrain;ytrain);(xtest;ytest)) format for each fold
// @param func1 {fn}        Function to be applied to x data
// @param func2 {fn}        Function to be applied to k
// @param k     {int}       Number of folds
// @param n     {int}       Number of repetitions
// @param feat  {#any[][]}  Matrix of features
// @param targ  {#any[]}    Vector of targets
// @return      {fn}        Projection of data split per fold
xv.i.idxN:{[func1;func2;k;n;feat;targ]
  xv.i.idx1[func1;func2;;feat;targ]@'n#k
  }

// @kind function
// @category private
// @fileoverview Apply funct to data split using specified indexing functions
// @param idx   {long[][]} Indicies to apply to data
// @param k     {int}      Number of folds
// @param n     {int}      Number of repetitions
// @param feat  {#any[][]} Matrix of features
// @param targ  {#any[]}   Vector of targets
// @param func  {fn}       Function which takes data as input
// @return      {}         Output of func with idx applied to data
xv.i.applyidx:{[idx;k;n;feat;targ;func]
  {[func;data]func data[]}[func]peach raze idx[k;n;feat;targ]
  }

// @kind function
// @category xv
// @fileoverview Cross validation for ascending indices split into k-folds
// @param k     {int}      Number of folds
// @param n     {int}      Number of repetitions
// @param feat  {#any[][]} Matrix of features
// @param targ  {#any[]}   Vector of targets
// @param func  {fn}       Function which takes data as input
// @return      {}         Output of func applied to each of the k-folds
xv.kfsplit:xv.i.applyidx xv.i.idxR . xv.i`splitidx`groupidx

// @kind function
// @category xv
// @fileoverview Cross validation for randomized non-repeating indices split 
//   into k-folds
// @param k     {int}      Number of folds
// @param n     {int}      Number of repetitions
// @param feat  {#any[][]} Matrix of features
// @param targ  {#any[]}   Vector of targets
// @param func  {fn}       Function which takes data as input
// @return      {}         Output of func applied to each of the k-folds
xv.kfshuff:xv.i.applyidx xv.i.idxN . xv.i`shuffidx`groupidx

// @kind function
// @category xv
// @fileoverview Stratified k-fold cross validation with an approximately equal
//    distribution of classes per fold
// @param k     {int}      Number of folds
// @param n     {int}      Number of repetitions
// @param feat  {#any[][]} Matrix of features
// @param targ  {#any[]}   Vector of targets
// @param func  {fn}       Function which takes data as input
// @return      {}         Output of func applied to each of the k-folds
xv.kfstrat:xv.i.applyidx xv.i.idxN . xv.i`stratidx`groupidx

// @kind function
// @category xv
// @fileoverview Roll-forward cross validation procedure
// @param k     {int}      Number of folds
// @param n     {int}      Number of repetitions
// @param feat  {#any[][]} Matrix of features
// @param targ  {#any[]}   Vector of targets
// @param func  {fn}       Function which takes data as input
// @return      {}         Output of func applied to each of the chained 
//   iterations
xv.tsrolls:xv.i.applyidx xv.i.idxR . xv.i`splitidx`tsrollsidx

// @kind function
// @category xv
// @fileoverview Chain-forward cross validation procedure
// @param k     {int}      Number of folds
// @param n     {int}      Number of repetitions
// @param feat  {#any[][]} Matrix of features
// @param targ  {#any[]}   Vector of targets
// @param func  {fn}       Function which takes data as input
// @return      {}         Output of func applied to each of the chained 
//   iterations
xv.tschain:xv.i.applyidx xv.i.idxR . xv.i`splitidx`tschainidx

// @kind function
// @category xv
// @fileoverview Percentage split cross validation procedure
// @param pc    {float}    (0-1) representing the percentage of validation data
// @param n     {int}      Number of repetitions
// @param feat  {#any[][]} Matrix of features
// @param targ  {#any[]}   Vector of targets
// @param func  {fn}       Function which takes data as input
// @return      {}         Output of func applied to each of the k-folds
xv.pcsplit:xv.i.applyidx{[pc;n;feat;targ]
  n#{[pc;x;y;z]
      (x;y)@\:/:(0,floor n*1-pc)_til n:count y
      }[pc;feat;targ]
  }

// @kind function
// @category xv
// @fileoverview Monte-Carlo cross validation using randomized non-repeating 
//   indices
// @param pc    {float}    (0-1) representing the percentage of validation data
// @param n     {int}      Number of repetitions
// @param feat  {#any[][]} Matrix of features
// @param targ  {#any[]}   Vector of targets
// @param func  {fn}       Function which takes data as input
// @return      {}         Output of func applied to each of the k-folds
xv.mcsplit:xv.i.applyidx{[pc;n;feat;targ]
  n#{[pc;x;y;z]
      (x;y)@\:/:(0,floor count[y]*1-pc)_{neg[n]?n:count x}y
      }[pc;feat;targ]
  }

// @kind function
// @category xv
// @fileoverview Default scoring function used in conjunction with .ml.xv/gs/rs
//   methods
// @param func  {fn}       Takes empty list, parameters and data as input
// @param p     {dict}     Hyperparameters
// @param data  {#any[][]} ((xtrain;xtest);(ytrain;ytest)) format
// @return      {float[]}  Scores outputted by func applied to p and data
xv.fitscore:{[func;p;data]
  .[.[func[][p]`:fit;data 0]`:score;data 1]`
  }

// Hyperparameter Search Functionality

// @kind function
// @category private
// @fileoverview Perform hyperparameter generation and cross validation
// @param pf   {fn}       Parameter function
// @param xv   {fn}       Cross validation function
// @param k    {int}      Number of folds
// @param n    {int}      Number of repetitions
// @param feat {#any[][]} Matrix of features
// @param targ {#any[]}   Vector of targets
// @param func {fn}       Function which takes data as input
// @param p    {dict}     Hyperparameters
// @return     {table}    Cross validation scores for each hyperparameter set
hp.i.xvpf:{[pf;xv;k;n;x;y;f;p]
  // generate hyperparameter sets
  p:pf p;
  // perform cross validation for each set
  p!(xv[k;n;x;y]f pykwargs@)@'p
  }

// @kind function
// @category private
// @fileoverview Hyperparameter search with option to test final model 
// @param sf     {fn}       Scoring function
// @param k      {int}      Number of folds
// @param n      {int}      Number of repetitions
// @param feat   {#any[][]} Matrix of features
// @param targ   {#any[]}   Vector of targets
// @param func   {fn}       Function which takes data as input
// @param p      {dict}     Dictionary of hyperparameters
// @param tsttyp {float}    Size of the holdout set used in a fitted grid 
//   search, where the best model is fit to the holdout set. If 0 the function 
//   will return scores for each fold for the given hyperparameters. If 
//   negative the data will be shuffled prior to designation of the holdout set
// @return       {}        Either validation or testing results from 
//   hyperparameter search
hp.i.search:{[sf;k;n;feat;targ;func;p;tsttyp]
  if[t=0;:sf[k;n;feat;targ;func;p]];
  i:(0,floor count[targ]*1-abs tsttyp)_$[t<0;xv.i.shuffle;til count@]targ;
  r:sf[k;n;feat i 0;targ i 0;func;p];
  res:func[pykwargs pr:first key desc avg each r](feat;targ)@\:/:i;
  (r;pr;res)
  }

// @kind function
// @category private
// @fileoverview Hyperparameter generation for .ml.gs
// @param pdict {dict}  Hyperparameters with all possible values for a given 
//    parameter specified by the user, e.g.
//    pdict = `random_state`max_depth!(42 72 84;1 3 4 7)
// @return      {table} All possible hyperparameter sets
hp.i.gsgen:{[pdict]
  key[pdict]!/:1_'(::)cross/value pdict
  }

// @kind function
// @category private
// @fileoverview Hyperparameter generation for .ml.rs
// @param pdict {dict}  Parameters with form `random_state`n`typ`p where 
//   random_state is the seed, n is the number of hyperparameters to generate 
//   (must equal 2^n for sobol), typ is the type of search (random/sobol) and p
//   is a dictionary of hyperparameter spaces - see documentation for more info
// @return      {table} Hyperparameters
hp.i.rsgen:{[pdict]
  // set default number of trials
  if[(::)~n:pdict`n;n:16];
  // check sobol trials = 2^n
  if[(`sobol=pdict`typ)&k<>floor k:xlog[2]n;
    '"trials must equal 2^n for sobol search"];
  // find numerical hyperparameter spaces
  num:where any`uniform`loguniform=\:first each p:pdict`p;
  // set random seed
  system"S ",string$[(::)~pdict`random_state;42;pdict`random_state];
  // import sobol sequence generator and check requirements
  pysobol:.p.import[`sobol_seq;`:i4_sobol_generate;<];
  genpts:$[`sobol~typ:pdict`typ;enlist each flip pysobol[count num;n];
    `random~typ;n;'"hyperparam type not supported"];
  // generate hyperparameters
  prms:distinct flip hp.i.hpgen[typ;n]each p,:num!p[num],'genpts;
  // take distinct sets
  if[n>dst:count prms;
    -1"Distinct hp sets less than n - returning ",string[dst]," sets."];
  prms}

// @kind function
// @category private
// @fileoverview Random/sobol hyperparameter generation for .ml.rs
// @param ns {symbol} Namespace - random or sobol
// @param n  {long}   Number of hyperparameter sets
// @param p  {dict}   Parameters
// @return   {#any}   Hyperparameters
hp.i.hpgen:{[ns;n;p]
  // split parameters
  p:@[;0;first](0;1)_p,();
  // respective parameter generation
  $[(typ:p 0)~`boolean;n?0b;
    typ in`rand`symbol;n?(),p[1]0;
    typ~`uniform;hp.i.uniform[ns]. p 1;
    typ~`loguniform;hp.i.loguniform[ns]. p 1;
    '"please enter a valid type"]}

// @kind function
// @category private
// @fileoverview Uniform number generator 
// @param ns  {symbol} Namespace - random or sobol
// @param lo  {long}   Lower bound
// @param hi  {long}   Higher bound
// @param typ {char}   Type of parameter, e.g. "i", "f", etc
// @param p   {num[]}  Parameters
// @return    {num[]}  Uniform numbers
hp.i.uniform:{[ns;lo;hi;typ;p]
  if[hi<lo;'"upper bound must be greater than lower bound"];
  hp.i[ns][`uniform][lo;hi;typ;p]
  }

// @kind function
// @category xv
// @fileoverview Generate list of log uniform numbers
// @param ns  {symbol} Namespace - random or sobol
// @param lo  {num}    Lower bound as power of 10
// @param hi  {num}    Higher bound as power of 10
// @param typ {char}   Type of parameter, e.g. "i", "f", etc
// @param p   {num[]}  Parameters
// @return    {num[]}  Log uniform numbers
hp.i.loguniform:xexp[10]hp.i.uniform::

// @kind function
// @category private
// @fileoverview Random uniform generator
// @param lo  {num}   Lower bound as power of 10
// @param hi  {num}   Higher bound as power of 10
// @param typ {char}  Type of parameter, e.g. "i", "f", etc
// @param n   {long}  Number of hyperparameter sets
// @return    {num[]} Random uniform numbers
hp.i.random.uniform:{[lo;hi;typ;n]
  lo+n?typ$hi-lo
  }

// @kind function
// @category private
// @fileoverview Sobol uniform generator
// @param lo  {num}     Lower bound as power of 10
// @param hi  {num}     Higher bound as power of 10
// @param typ {char}    Type of parameter, e.g. "i", "f", etc
// @param seq {float[]} Sobol sequence
// @return    {num[]}   Uniform numbers from sobol sequence
hp.i.sobol.uniform:{[lo;hi;typ;seq]
  typ$lo+(hi-lo)*seq
  }

// @kind function
// @category gs
// @fileoverview Cross validated parameter grid search applied to data with 
//   ascending split indices
// @param k      {int}      Number of folds
// @param n      {int}      Number of repetitions
// @param feat   {#any[][]} Matrix of features
// @param targ   {#any[]}   Vector of targets
// @param func   {fn}       Function that takes parameters and data as input 
//   and returns a score
// @param p      {dict}     Dictionary of hyperparameters
// @param tsttyp {float}    Size of the holdout set used in a fitted grid 
//   search, where the best model is fit to the holdout set. If 0 the function 
//   will return scores for each fold for the given hyperparameters. If 
//   negative the data will be shuffled prior to designation of the holdout set
// @return       {}         Scores for hyperparameter sets on each of the k 
//   folds for all values of h and additionally returns the best hyperparameters 
//   and score on the holdout set for 0 < h <=1.
gs.kfsplit:hp.i.search hp.i.xvpf[hp.i.gsgen;xv.kfsplit]

// @kind function
// @category gs
// @fileoverview Cross validated parameter grid search applied to data with 
//   shuffled split indices
// @param k      {int}      Number of folds
// @param n      {int}      Number of repetitions
// @param feat   {#any[][]} Matrix of features
// @param targ   {#any[]}   Vector of targets
// @param func   {fn}       Function that takes parameters and data as input
//   and returns a score
// @param p      {dict}     Dictionary of hyperparameters
// @param tsttyp {float}    Size of the holdout set used in a fitted grid 
//   search, where the best model is fit to the holdout set. If 0 the function 
//   will return scores for each fold for the given hyperparameters. If 
//   negative the data will be shuffled prior to designation of the holdout set
// @return       {}         Scores for hyperparameter sets on each of the k 
//   folds for all values of h and additionally returns the best 
//   hyperparameters and score on the holdout set for 0 < h <=1.
gs.kfshuff:hp.i.search hp.i.xvpf[hp.i.gsgen;xv.kfshuff]

// @kind function
// @category gs
// @fileoverview Cross validated parameter grid search applied to data with an 
//   equi-distributions of targets per fold
// @param k      {int}      Number of folds
// @param n      {int}      Number of repetitions
// @param feat   {#any[][]} Matrix of features
// @param targ   {#any[]}   Vector of targets
// @param func   {fn}       Function that takes parameters and data as input
//   and returns a score
// @param p      {dict}     Dictionary of hyperparameters
// @param tsttyp {float}    Size of the holdout set used in a fitted grid 
//   search, where the best model is fit to the holdout set. If 0 the function 
//   will return scores for each fold for the given hyperparameters. If 
//   negative the data will be shuffled prior to designation of the holdout set
// @return       {}         Scores for hyperparameter sets on each of the k 
//   folds for all values of h and additionally returns the best 
//   hyperparameters and score on the holdout set for 0 < h <=1.
gs.kfstrat:hp.i.search hp.i.xvpf[hp.i.gsgen;xv.kfstrat]

// @kind function
// @category gs
// @fileoverview Cross validated parameter grid search applied to roll forward 
//   time-series sets
// @param k      {int}      Number of folds
// @param n      {int}      Number of repetitions
// @param feat   {#any[][]} Matrix of features
// @param targ   {#any[]}   Vector of targets
// @param func   {fn}       Function that takes parameters and data as input
//   and returns a score
// @param p      {dict}     Dictionary of hyperparameters
// @param tsttyp {float}    Size of the holdout set used in a fitted grid 
//   search, where the best model is fit to the holdout set. If 0 the function 
//   will return scores for each fold for the given hyperparameters. If 
//   negative the data will be shuffled prior to designation of the holdout set
// @return       {}         Scores for hyperparameter sets on each of the k 
//   folds for all values of h and additionally returns the best 
//   hyperparameters and score on the holdout set for 0 < h <=1.
gs.tsrolls:hp.i.search hp.i.xvpf[hp.i.gsgen;xv.tsrolls]

// @kind function
// @category gs
// @fileoverview Cross validated parameter grid search applied to chain forward 
//   time-series sets
// @param k      {int}      Number of folds
// @param n      {int}      Number of repetitions
// @param feat   {#any[][]} Matrix of features
// @param targ   {#any[]}   Vector of targets
// @param func   {fn}       Function that takes parameters and data as input
//   and returns a score
// @param p      {dict}     Dictionary of hyperparameters
// @param tsttyp {float}    Size of the holdout set used in a fitted grid 
//   search, where the best model is fit to the holdout set. If 0 the function 
//   will return scores for each fold for the given hyperparameters. If 
//   negative the data will be shuffled prior to designation of the holdout set
// @return       {}         Scores for hyperparameter sets on each of the k 
//   folds for all values of h and additionally returns the best 
//   hyperparameters and score on the holdout set for 0 < h <=1.
gs.tschain:hp.i.search hp.i.xvpf[hp.i.gsgen;xv.tschain]

// @kind function
// @category gs
// @fileoverview Cross validated parameter grid search applied to percentage 
//   split dataset
// @param pc     {float}    (0-1) representing percentage of validation data
// @param n      {int}      Number of repetitions
// @param feat   {#any[][]} Matrix of features
// @param targ   {#any[]}   Vector of targets
// @param func   {fn}       Function that takes parameters and data as input
//   and returns a score
// @param p      {dict}     Dictionary of hyperparameters
// @param tsttyp {float}    Size of the holdout set used in a fitted grid 
//   search, where the best model is fit to the holdout set. If 0 the function 
//   will return scores for each fold for the given hyperparameters. If 
//   negative the data will be shuffled prior to designation of the holdout set
// @return       {}         Scores for hyperparameter sets on each of the k 
//   folds for all values of h and additionally returns the best 
//   hyperparameters and score on the holdout set for 0 < h <=1.
gs.pcsplit:hp.i.search hp.i.xvpf[hp.i.gsgen;xv.pcsplit]

// @kind function
// @category gs
// @fileoverview Cross validated parameter grid search applied to randomly 
//   shuffled data and validated on a percentage holdout set
// @param pc     {float}    (0-1) representing percentage of validation data
// @param n      {int}      Number of repetitions
// @param feat   {#any[][]} Matrix of features
// @param targ   {#any[]}   Vector of targets
// @param func   {fn}       Function that takes parameters and data as input
//   and returns a score
// @param p      {dict}     Dictionary of hyperparameters
// @param tsttyp {float}    Size of the holdout set used in a fitted grid 
//   search, where the best model is fit to the holdout set. If 0 the function 
//   will return scores for each fold for the given hyperparameters. If 
//   negative the data will be shuffled prior to designation of the holdout set
// @return       {}         Scores for hyperparameter sets on each of the k 
//   folds for all values of h and additionally returns the best 
//   hyperparameters and score on the holdout set for 0 < h <=1.
gs.mcsplit:hp.i.search hp.i.xvpf[hp.i.gsgen;xv.mcsplit]

// @kind function
// @category rs
// @fileoverview Cross validated parameter random search applied to data with
//   ascending split indices
// @param k      {int}      Number of folds
// @param n      {int}      Number of repetitions
// @param feat   {#any[][]} Matrix of features
// @param targ   {#any[]}   Vector of targets
// @param func   {fn}       Function that takes parameters and data as input
//   and returns a score
// @param p      {dict}     Dictionary of hyperparameters to be searched with 
//   format `typ`random_state`n`p where typ is the type of search 
//   (random/sobol), random_state is the seed, n is the number of 
//   hyperparameter sets and p is a dictionary of parameters - see 
//   documentation for more info.
// @param tsttyp {float}    Size of the holdout set used in a fitted grid 
//   search, where the best model is fit to the holdout set. If 0 the function 
//   will return scores for each fold for the given hyperparameters. If 
//   negative the data will be shuffled prior to designation of the holdout set
// @return       {}         Scores for hyperparameter sets on each of the k 
//   folds for all values of h and additionally returns the best 
//   hyperparameters and score on the holdout set for 0 < h <=1.
rs.kfsplit:hp.i.search hp.i.xvpf[hp.i.rsgen;xv.kfsplit]

// @kind function
// @category rs
// @fileoverview Cross validated parameter random search applied to data with 
//   shuffled split indices
// @param k      {int}      Number of folds
// @param n      {int}      Number of repetitions
// @param feat   {#any[][]} Matrix of features
// @param targ   {#any[]}   Vector of targets
// @param func   {fn}       Function that takes parameters and data as input
//   and returns a score
// @param p      {dict}     Dictionary of hyperparameters to be searched with 
//   format `typ`random_state`n`p where typ is the type of search 
//   (random/sobol), random_state is the seed, n is the number of 
//   hyperparameter sets and p is a dictionary of parameters - see 
//   documentation for more info.
// @param tsttyp {float}    Size of the holdout set used in a fitted grid 
//   search, where the best model is fit to the holdout set. If 0 the function 
//   will return scores for each fold for the given hyperparameters. If 
//   negative the data will be shuffled prior to designation of the holdout set
// @return       {}         Scores for hyperparameter sets on each of the k 
//   folds for all values of h and additionally returns the best 
//   hyperparameters and score on the holdout set for 0 < h <=1.
rs.kfshuff:hp.i.search hp.i.xvpf[hp.i.rsgen;xv.kfshuff]

// @kind function
// @category rs
// @fileoverview Cross validated parameter random search applied to data with 
//   an equi-distributions of targets per fold
// @param k      {int}      Number of folds
// @param n      {int}      Number of repetitions
// @param feat   {#any[][]} Matrix of features
// @param targ   {#any[]}   Vector of targets
// @param func   {fn}       Function that takes parameters and data as input
//   and returns a score
// @param p      {dict}     Dictionary of hyperparameters to be searched with 
//   format `typ`random_state`n`p where typ is the type of search 
//   (random/sobol), random_state is the seed, n is the number of 
//   hyperparameter sets and p is a dictionary of parameters - see 
//   documentation for more info.
// @param tsttyp {float}    Size of the holdout set used in a fitted grid 
//   search, where the best model is fit to the holdout set. If 0 the function 
//   will return scores for each fold for the given hyperparameters. If 
//   negative the data will be shuffled prior to designation of the holdout set
// @return       {}         Scores for hyperparameter sets on each of the k 
//   folds for all values of h and additionally returns the best 
//   hyperparameters and score on the holdout set for 0 < h <=1.
rs.kfstrat:hp.i.search hp.i.xvpf[hp.i.rsgen;xv.kfstrat]

// @kind function
// @category rs
// @fileoverview Cross validated parameter random search applied to roll 
//   forward time-series sets
// @param k      {int}      Number of folds
// @param n      {int}      Number of repetitions
// @param feat   {#any[][]} Matrix of features
// @param targ   {#any[]}   Vector of targets
// @param func   {fn}       Function that takes parameters and data as input
//   and returns a score
// @param p      {dict}     Dictionary of hyperparameters to be searched with 
//   format `typ`random_state`n`p where typ is the type of search 
//   (random/sobol), random_state is the seed, n is the number of 
//   hyperparameter sets and p is a dictionary of parameters - see 
//   documentation for more info.
// @param tsttyp {float}    Size of the holdout set used in a fitted grid 
//   search, where the best model is fit to the holdout set. If 0 the function 
//   will return scores for each fold for the given hyperparameters. If 
//   negative the data will be shuffled prior to designation of the holdout set
// @return       {}         Scores for hyperparameter sets on each of the k 
//   folds for all values of h and additionally returns the best 
//   hyperparameters and score on the holdout set for 0 < h <=1.
rs.tsrolls:hp.i.search hp.i.xvpf[hp.i.rsgen;xv.tsrolls]

// @kind function
// @category rs
// @fileoverview Cross validated parameter random search applied to chain 
//   forward time-series sets
// @param k      {int}      Number of folds
// @param n      {int}      Number of repetitions
// @param feat   {#any[][]} Matrix of features
// @param targ   {#any[]}   Vector of targets
// @param func   {fn}       Function that takes parameters and data as input
//   and returns a score
// @param p      {dict}     Dictionary of hyperparameters to be searched with 
//   format `typ`random_state`n`p where typ is the type of search 
//   (random/sobol), random_state is the seed, n is the number of 
//   hyperparameter sets and p is a dictionary of parameters - see 
//   documentation for more info.
// @param tsttyp {float}    Size of the holdout set used in a fitted grid 
//   search, where the best model is fit to the holdout set. If 0 the function 
//   will return scores for each fold for the given hyperparameters. If 
//   negative the data will be shuffled prior to designation of the holdout set
// @return       {}         Scores for hyperparameter sets on each of the k 
//   folds for all values of h and additionally returns the best 
//   hyperparameters and score on the holdout set for 0 < h <=1.
rs.tschain:hp.i.search hp.i.xvpf[hp.i.rsgen;xv.tschain]

// @kind function
// @category rs
// @fileoverview Cross validated parameter random search applied to percentage 
//   split dataset
// @param pc     {float}    (0-1) representing percentage of validation data
// @param n      {int}      Number of repetitions
// @param feat   {#any[][]} Matrix of features
// @param targ   {#any[]}   Vector of targets
// @param func   {fn}       Function that takes parameters and data as input
//   and returns a score
// @param p      {dict}     Dictionary of hyperparameters to be searched with 
//   format `typ`random_state`n`p where typ is the type of search 
//   (random/sobol), random_state is the seed, n is the number of 
//   hyperparameter sets and p is a dictionary of parameters - see 
//   documentation for more info.
// @param tsttyp {float}    Size of the holdout set used in a fitted grid 
//   search, where the best model is fit to the holdout set. If 0 the function 
//   will return scores for each fold for the given hyperparameters. If 
//   negative the data will be shuffled prior to designation of the holdout set
// @return       {}         Scores for hyperparameter sets on each of the k 
//   folds for all values of h and additionally returns the best 
//   hyperparameters and score on the holdout set for 0 < h <=1.
rs.pcsplit:hp.i.search hp.i.xvpf[hp.i.rsgen;xv.pcsplit]

// @kind function
// @category rs
// @fileoverview Cross validated parameter random search applied to randomly 
//   shuffled data and validated on a percentage holdout set
// @param pc     {float}    (0-1) representing percentage of validation data
// @param n      {int}      Number of repetitions
// @param feat   {#any[][]} Matrix of features
// @param targ   {#any[]}   Vector of targets
// @param func   {fn}       Function that takes parameters and data as input
//   and returns a score
// @param p      {dict}     Dictionary of hyperparameters to be searched with 
//   format `typ`random_state`n`p where typ is the type of search 
//   (random/sobol), random_state is the seed, n is the number of 
//   hyperparameter sets and p is a dictionary of parameters - see 
//   documentation for more info.
// @param tsttyp {float}    Size of the holdout set used in a fitted grid 
//   search, where the best model is fit to the holdout set. If 0 the function 
//   will return scores for each fold for the given hyperparameters. If 
//   negative the data will be shuffled prior to designation of the holdout set
// @return       {}         Scores for hyperparameter sets on each of the k 
//   folds for all values of h and additionally returns the best 
//   hyperparameters and score on the holdout set for 0 < h <=1.
rs.mcsplit:hp.i.search hp.i.xvpf[hp.i.rsgen;xv.mcsplit]

// Multi-processing Functionality

//  Load multi-processing modules
loadfile`:util/mproc.q
loadfile`:util/pickle.q

//  If multiple processes are available, multi-process cross validation library
if[0>system"s";mproc.init[abs system"s"]enlist".ml.loadfile`:util/pickle.q"];
xv.picklewrap:{picklewrap[(0>system"s")&.p.i.isw x]x}
