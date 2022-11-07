#include <R.h>
#include <R_ext/Utils.h>
#include "chunkloop.h"
#include "looptest.h"

/*

  Egeyer.c

  $Revision: 1.9 $     $Date: 2022/10/22 10:09:51 $

  Copyright (C) Adrian Baddeley, Ege Rubak and Rolf Turner 2001-2018
  Licence: GNU Public Licence >= 2

  Part of C implementation of 'eval' for Geyer interaction

  Calculates change in saturated count 

  (xquad, yquad): quadscheme 
  (xdata, ydata): data
  tdata: unsaturated pair counts for data pattern
  quadtodata[j] = i   if quad[j] == data[i]  (indices start from ZERO)
  
  Assumes point patterns are sorted in increasing order of x coordinate

*/

double sqrt(double x);

void Egeyer(
  /* inputs */
  int *nnquad,
  double *xquad,
  double *yquad,
  int *quadtodata,
  int *nndata,
  double *xdata,
  double *ydata,
  int *tdata,
  double *rrmax,
  double *ssat,
  /* output */
  double *result
) {
  int nquad, ndata, maxchunk, j, i, ileft, dataindex, isdata;
  double xquadj, yquadj, rmax, sat, r2max, r2maxpluseps, xleft, dx, dy, dx2, d2;
  double tbefore, tafter, satbefore, satafter, delta, totalchange;

  nquad = *nnquad;
  ndata = *nndata;
  rmax  = *rrmax;
  sat   = *ssat;

  if(nquad == 0 || ndata == 0) 
    return;

  r2max = rmax * rmax;
  r2maxpluseps = r2max + EPSILON(r2max);

  ileft = 0;

  OUTERCHUNKLOOP(j, nquad, maxchunk, 65536) {
    R_CheckUserInterrupt();
    INNERCHUNKLOOP(j, nquad, maxchunk, 65536) {
      totalchange = 0.0;
      xquadj = xquad[j];
      yquadj = yquad[j];
      dataindex = quadtodata[j];
      isdata = (dataindex >= 0);

      /* 
	 adjust starting point
      */
      xleft  = xquadj - rmax;
      while((xdata[ileft] < xleft) && (ileft+1 < ndata))
	++ileft;

      /* 
	 process until dx > rmax
      */
      for(i=ileft; i < ndata; i++) {
	dx = xdata[i] - xquadj;
	dx2 = dx * dx;
	if(dx2 > r2maxpluseps)
	  break;
	if(i != dataindex) {
	  dy = ydata[i] - yquadj;
	  d2 = dx2 + dy * dy;
	  if(d2 <= r2max) {
	    /* effect of adding dummy point j or 
	       negative effect of removing data point */
	    tbefore = tdata[i];
	    tafter  = tbefore + ((isdata) ? -1 : 1);
	    /* effect on saturated values */
	    satbefore = (double) ((tbefore < sat)? tbefore : sat);
	    satafter  = (double) ((tafter  < sat)? tafter  : sat);
	    /* sum changes over all i */
	    delta = satafter - satbefore; 
	    totalchange += ((isdata) ? -delta : delta);
	  }
	}
      }
      result[j] = totalchange;
    }
  }
}



