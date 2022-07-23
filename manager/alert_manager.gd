extends Node

################################################
################### SIGNALS ####################
################################################

################################################
#################### ENUMS #####################
################################################

enum {
	CHANNEL_UPDATE = 0,
	CHANNEL_FOLLOW,
	CHANNEL_SUBSCRIBE,
	CHANNEL_SUBSCRIPTION_END,
	CHANNEL_SUBSCRIPTION_GIFT,
	CHANNEL_SUSCRIPTION_MESSAGE,
	CHANNEL_CHEER,
	CHANNEL_RAID,
	CHANNEL_BAN,
	CHANNEL_UNBAN,
	CHANNEL_MODERATOR_ADD,
	CHANEL_MODERATOR_REMOVED,
	CHANNEL_POINTS_CUSTOM_REWARD_ADD,
	CHANNEL_POINTS_CUSTOM_REWARD_UPDATE,
	CHANNEL_POINTS_CUSTOM_REWARD_REMOVE,
	CHANNEL_POINTS_CUSTOM_REWARD_REDEMPTION_ADD,
	CHANNEL_POINTS_CUSTOM_REWARD_REDEMPTION_UPDATE,
	CHANNEL_POLL_BEGIN,
	CHANNEL_POLL_PROGRESS,
	CHANNEL_POLL_END,
	CHANNEL_PREDICTION_BEGIN,
	CHANNEL_PREDICTION_PROGRESS,
	CHANNEL_PREDICTION_LOCK,
	CHANNEL_PREDICTION_END,
	DROP_ENTITLEMENT_GRANT,
	EXTENSION_BITS_TRANSACTION_CREATE,
	GOAL_BEGIN,
	GOAL_PROGRESS,
	GOAL_END,
	HYPE_TRAIN_BEGIN,
	HYPE_TRAIN_PROGRESS,
	HYPE_TRAIN_END,
	STREAM_ONLINE,
	STREAM_OGGLINE,
	USER_AUTHORIZATION_GRANT,
	USER_AUTHORIZATION_REVOKE,
	USER_UPDATE,
}


################################################
################## CONSTANTS ###################
################################################

################################################
################### EXPORTS ####################
################################################

################################################
################### PUBLIC #####################
################################################

################################################
################### PRIVATE ####################
################################################

var http_server : HTTPServer = HTTPServer.new()

################################################
################### ONREADY ####################
################################################




