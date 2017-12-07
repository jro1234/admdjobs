

import sampling_functions
'''
This file provides an interface for using sampling functions.
The sampling scheme should be programmed in such a function by
the user and saved in sampling_functions.py. These are called
through sampling_function defined in get_one, which handles
the arguments and provides the routines that should be replicated
for all sampling functions, currently this is simply converting
them to a runnable form, ie trajectory objects.
'''

def get_one(name_func): 

    name_backup_func = 'random_sampling'
 
    _sampling_function = getattr(sampling_functions, name_func)
    print("Retrieved sampling function: ", _sampling_function) 
    backup_sampling_function = getattr(sampling_functions, name_backup_func) 
    print("Backup sampling function: ", backup_sampling_function) 

    assert callable(_sampling_function)
    assert callable(backup_sampling_function)
 
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
             
            sampled_frames = None

            while not sampled_frames:

                try:
                    sampled_frames = sf(project, number, *args)

                except Exception as e:
                    print("Sampling was unsuccessful due to this error:")
                    print(e)

                    if sf == backup_sampling_function:
                        print("This error must be fixed to generate sampled frames")
                        return []

                    else:
                        sf = backup_sampling_function

            for i,frame in enumerate(sampled_frames): 
                trajectories.append( 
                    project.new_trajectory( 
                    frame, length[i], engine) 
                ) 
 
        return trajectories 
 
 
    return sampling_function 

