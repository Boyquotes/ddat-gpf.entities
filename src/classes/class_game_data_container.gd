extends Resource

class_name GameDataContainer

##############################################################################
#
# GameDataContainer is a placeholder resource for the 'DDAT_Runtime_Framework'*.
# *The 'DDAT_Runtime_Framework' is a package for the DDAT Prototyping Framework.
#
# A gameDataContainer is used to store information about a player's save
# state; i.e. the variables that the GameMeta state will load
# GameDataContainers are loaded as part of the GlobalData singleton (part of
# the 'DDAT_Core' package within the DDAT Prototyping Framework).
#
# Developers can extend this class to create their own data containers
# for different parts of their game, and then include objects of these
# extended data containers as part of a save state data container.
#
# DEPENDENCIES:
# DDAT_Prototyping_Framework.DDAT_Core
# DDAT_Prototyping_Framework.DDAT_Runtime
#
##############################################################################

# warning-ignore:unused_class_variable
export(int) var example_int_data := 0
# warning-ignore:unused_class_variable
export(float) var example_float_data := 1.0
# warning-ignore:unused_class_variable
export(bool) var example_bool_data := false
