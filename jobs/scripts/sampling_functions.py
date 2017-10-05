


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
 1. Query some attribute of the model
 2. Weights based on analysis of this attribute
 3. Sample a selection of frames from trajectories
 3. Returns these frames

'''



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
        s =  np.sum(c, axis=1)
        if 0 not in s:
            return data, c


def random_restart(project, number=1):
    trajlist = list()

    if len(project.trajectories) > 0:
        print("Using random vector to select new frames")
        [trajlist.append(project.trajectories.pick().pick()) for _ in range(number)]

    return trajlist


def xplor_microstates(project, number=1):
    '''
    This one is the same as project.new_ml_trajectory
    '''

    data, c = get_model(project)
    q = 1/np.sum(c, axis=1)
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
    print("...we have chosen these states:\n", [(s, q[s]) for s in state_picks])

    filelist = data['input']['trajectories']

    picks = [
        frame_state_list[state][np.random.randint(0,
                len(frame_state_list[state]))]
        for state in state_picks
        ]

    [trajlist.append(filelist[pick[0]][pick[1]]) for pick in picks]

    print("Trajectory picks list:\n", trajlist)
    return trajlist


def get_one(name_func):

    _sampling_function = globals()[name_func]
    print("Retrieved sampling function: ", _sampling_function)
    backup_sampling_function = random_restart
    print("Backup sampling function: ", backup_sampling_function)

    # Use Sampled Frames to make New Trajectories
    def sampling_function(project, engine, length, number, *args):

        trajectories = list()

        if isinstance(length, int):
            assert(isinstance(number, int))
            length = [length] * number

        if isinstance(length, list):
            if number is None:
                number = len(length)

            if len(project.models) == 0:
                sf = backup_sampling_function
            else:
                sf = _sampling_function
            
            for i,frame in enumerate(sf(project, number, *args)):
                trajectories.append(
                    project.new_trajectory(
                    frame, length[i], engine)
                )

        return trajectories


    return sampling_function

