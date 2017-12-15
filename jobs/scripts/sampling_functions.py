

from __future__ import print_function

import numpy as np


'''
This file contains functions that sample from trajectory data
using a model. One sampling function is special "randomm_restart",
this one does not use a model and provides a random selection
of restarting frames. It is used as a backup sampling function
incase no model is available. To create a new sampling function,
see the examples. 

The requirements for a full-fledged sampling function:

 0. Call signature: project, number, additional arguments

 1. Get a model with function 'get_model'
    - currently returns last model, can expand functionality later
    - it checks that each microstate in the model is populated
    - then returns a tuple of: model data, count matrix

 2. Query some attribute of the model
    - only the count matrix, transition matrix, dtrajs,
      and a couple other MSM elements are available
      in the model data object. Can add more at our
      liesure.

 3. Weights based on analysis of this attribute

 4. Sample a selection of frames from trajectories
    - use something like the np.choice shown in
      xplor_microstates. here the weights were given
      by a vector with probability for each state i.

 5. Returns these frames
    - these frames are converted to trajectories for execution
      by the sampling interface component, no need to do

'''



def long_trajectories(project, number=1, trajectories=None, uselast=True):

    trajlist = list()

    if trajectories is None:
        # TODO could also use first, maybe use
        #      argument "selection" to choose option
        if uselast:
            trajectories = list(reversed(list(
                             project.trajectories.sorted(
                             lambda t: t.created))))[:number]

        else:
            trajectories = [t for n,t in enumerate(project.trajectories) if n < number]

    if len(trajectories) > 0:

        print("Extending the trajectory selection")

        for traj in trajectories:
            trajlist.append(traj[len(traj)])

    return trajlist


def random_sampling(project, number=1):

    trajlist = list()

    if len(project.trajectories) > 0:

        print("Using random vector to select new frames")

        [trajlist.append(project.trajectories.pick().pick()) for _ in range(number)]

    return trajlist


def explore_microstates(project, number=1):
    '''
    This one is the same as project.new_ml_trajectory
    '''

    data, c = get_model(project)
    # TODO verify axis 0 is the columns
    # TODO dont' do above todo, but ...
    #      do ceiling(average(rowcount, colcount)) as weight
    q = 1/np.sum(c, axis=1)
    #q = 1/np.sum(c, axis=0)
    trajlist = list()

    # not a good method to get n_states
    # populated clusters in
    # data['msm']['C'] may be less than k
    #n_states = data['clustering']['k']
    n_states = len(c)

    modeller = data['input']['modeller']

    outtype = modeller.outtype

    # the stride of the analyzed trajectories
    used_stride = modeller.engine.types[outtype].stride

    # all stride for full trajectories
    full_strides = modeller.engine.full_strides

    frame_state_list = {n: [] for n in range(n_states)}
    for nn, dt in enumerate(data['clustering']['dtrajs']):
        for mm, state in enumerate(dt):
            # if there is a full traj with existing frame, use it
            if any([(mm * used_stride) % stride == 0 for stride in full_strides]):
                frame_state_list[state].append((nn, mm * used_stride))

    # remove states that do not have at least one frame
    for k in range(n_states):
        if len(frame_state_list[k]) == 0:
            q[k] = 0.0

    # and normalize the remaining ones
    q /= np.sum(q)

    state_picks = np.random.choice(np.arange(len(q)), size=number, p=q)

    print("Using probability vector for states q:\n", q)

    filelist = data['input']['trajectories']

    print("FILELIST: ", len(filelist), "entries, with",
          len(project.trajectories), "trajectories actually stored")

    for f in filelist:
        print(f)

    picks = list()
    for state in state_picks:
        pick = frame_state_list[state][np.random.randint(0,
                len(frame_state_list[state]))]
        print("state, probability, pick: ", state, q[state], pick)
        picks.append(pick)

    ###picks = [
    ###    frame_state_list[state][np.random.randint(0,
    ###            len(frame_state_list[state]))]
    ###    for state in state_picks
    ###    ]

    [trajlist.append(filelist[pick[0]][pick[1]]) for pick in picks]

    print("Trajectory picks list:\n", trajlist)
    return trajlist


def MinMaxScale(X, min=-1, max=1):
  X_std = (X - X.min(axis=0)) / (X.max(axis=0) - X.min(axis=0))
  X_scaled = X_std * (max - min) + min
  return X_scaled

def select_restart_state(values, select_type, microstates, nparallel=1, parameters=None):
    if select_type == 'sto_inv_linear':
        inv_values = 1.0 / values
        p = inv_values / np.sum(inv_values)
    return np.random.choice(microstates, p = p, size=nparallel)


def explore_macrostates(project, number=1):
  import pyemma
  import msmtools
  print("USING EXPLORE MACROSTATES STRATEGY")
  data, c = get_model(project)
  counts=np.sum(c, axis=1)
  array_ok=msmtools.estimation.largest_connected_set(c)
  msmtools.estimation.is_connected(c[array_ok,:][:,array_ok])
  p=msmtools.estimation.transition_matrix(c[array_ok,:][:,array_ok])
  current_MSM_obj = pyemma.msm.markov_model(p)
  #num_eigenvecs_to_compute=5
  current_eigenvecs = np.real(current_MSM_obj.eigenvectors_right())#num_eigenvecs_to_compute)
  num_eigenvecs_to_compute=current_eigenvecs.shape[0]
  current_timescales = current_MSM_obj.timescales()
  current_eigenvals = np.real(current_MSM_obj.eigenvalues())
  print(current_timescales)
  projected_microstate_coords_scaled = MinMaxScale(current_eigenvecs[:,1:])
  projected_microstate_coords_scaled *= np.sqrt(current_timescales[:num_eigenvecs_to_compute-1] / current_timescales[0]).reshape(1, num_eigenvecs_to_compute-1)
  kin_cont = np.cumsum(-1./np.log(np.abs(current_eigenvals[1:])))/2.
  frac_kin_content=0.9
  cut = kin_cont[kin_cont < kin_cont.max()*frac_kin_content]
  num_macrostates = max(cut.shape[0],1)
  print(num_macrostates)
  num_kmeans_iter=10
  kmeans_obj = pyemma.coordinates.cluster_kmeans(data=projected_microstate_coords_scaled, k=num_macrostates, max_iter=num_kmeans_iter)
  macrostate_assignment_of_visited_microstates = kmeans_obj.assign()[0]             
  macrostate_assignment_of_visited_microstates
  corrected=np.zeros(c.shape[0])
  corrected[array_ok]=macrostate_assignment_of_visited_microstates
  not_connected_macrostates=[i for i in range(c.shape[0]) if i not in array_ok]
  for n,i in enumerate(not_connected_macrostates):
    #print(i)
    corrected[i]=n+num_macrostates
  print(corrected)
  counts=np.sum(c,axis=0)
  #[array_ok,:][:,array_ok]
  macrostate_counts = np.array([np.sum(counts[corrected == macrostate_label]) for macrostate_label in range(num_macrostates+len(not_connected_macrostates))])
  selected_macrostate = select_restart_state(macrostate_counts[macrostate_counts > 0], 'sto_inv_linear', np.arange(num_macrostates+len(not_connected_macrostates))[macrostate_counts > 0], nparallel=number)
  restart_state=np.empty((0))
  for i in range(number):
    selected_macrostate_mask = (corrected == selected_macrostate[i])
    counts_in_selected_macrostate = counts[selected_macrostate_mask]
    add_microstate=select_restart_state(counts_in_selected_macrostate, 'sto_inv_linear', np.arange(c.shape[0])[selected_macrostate_mask], nparallel=1)
    print(selected_macrostate[i], add_microstate)
    restart_state=np.append(restart_state,add_microstate)
  state_picks=restart_state.astype('int')
  n_states = len(c)
  modeller = data['input']['modeller']
  outtype = modeller.outtype
  # the stride of the analyzed trajectories
  used_stride = modeller.engine.types[outtype].stride
  # all stride for full trajectories
  full_strides = modeller.engine.full_strides
  frame_state_list = {n: [] for n in range(n_states)}
  for nn, dt in enumerate(data['clustering']['dtrajs']):
      for mm, state in enumerate(dt):
          # if there is a full traj with existing frame, use it
          if any([(mm * used_stride) % stride == 0 for stride in full_strides]):
              frame_state_list[state].append((nn, mm * used_stride))
  # remove states that do not have at least one frame
  filelist = data['input']['trajectories']
  print("FILELIST: ", len(filelist), "entries, with", len(project.trajectories), "trajectories actually stored")
  for f in filelist:
          print(f)
  picks = list()
  for state in state_picks:
    pick = frame_state_list[state][np.random.randint(0,
            len(frame_state_list[state]))]
    print("state, probability, pick: ", state, pick)
    picks.append(pick)
  trajlist = list()
  [trajlist.append(filelist[pick[0]][pick[1]]) for pick in picks]
  print("Trajectory picks list:\n", trajlist)
  return trajlist


# TODO make get_model able to search the model data with a
#      list of keys to query data from 'model.data'
# TODO model data check feature to check something about model
#      before returning it. 
def get_model(project):
    models = sorted(project.models, reverse=True, key=lambda m: m.__time__)
    for model in models:
        # Would have to import Model class
        # definition for this check
        #assert(isinstance(model, Model))
        data = model.data
        c = data['msm']['C']
        # TODO verify axis 0 is the columns
        s =  np.sum(c, axis=1)
        #s =  np.sum(c, axis=0)
        if 0 not in s:
            return data, c


