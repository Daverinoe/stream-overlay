extends Node
class_name SubHelper

################################################
#################### ENUMS #####################
################################################

enum {
	CHAT_READ = 0,
	CHAT_EDIT,
	CHANNEL_UPDATE,
	CHANNEL_FOLLOW,
	CHANNEL_SUBSCRIBE,
	CHANNEL_SUBSCRIPTION_END,
	CHANNEL_SUBSCRIPTION_GIFT,
	CHANNEL_SUBSCRIPTION_MESSAGE,
	CHANNEL_CHEER,
	CHANNEL_RAID,
	CHANNEL_BAN,
	CHANNEL_UNBAN,
	CHANNEL_MODERATE,
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
	STREAM_OFFLINE,
	USER_AUTHORIZATION_GRANT,
	USER_AUTHORIZATION_REVOKE,
	USER_UPDATE,
}

################################################
################### PRIVATE ####################
################################################

var scopes : Dictionary = {
	"chat.read": "chat:read",
	"chat.edit": "chat:edit",
	"channel.subscribe": "channel:read:subscriptions",
	"channel.subscription.end": "channel:read:subscriptions",
	"channel.subscription.gift": "channel:read:subscriptions",
	"channel.subscription.message": "channel:read:subscriptions",
	"channel.cheer": "bits:read",
	"channel.ban": "channel:moderate",
	"channel.unban": "channel:moderate",
	"channel.moderate": "channel:moderate",
	"channel.moderator.add": "moderation:read",
	"channel.moderator.remove": "moderation:read",
	"channel.channel_points_custom_reward.add": "channel:manage:redemptions",
	"channel.channel_points_custom_reward.update": "channel:manage:redemptions",
	"channel.channel_points_custom_reward.remove": "channel:manage:redemptions",
	"channel.channel_points_custom_reward_redemption.add": "channel:manage:redemptions",
	"channel.channel_points_custom_reward_redemption.update": "channel:manage:redemptions",
	"channel.poll.begin": "channel:manage:polls",
	"channel.poll.progress": "channel:manage:polls",
	"channel.poll.end": "channel:manage:polls",
	"channel.prediction.begin": "channel:manage:predictions",
	"channel.prediction.progress": "channel:manage:predictions",
	"channel.prediction.lock": "channel:manage:predictions",
	"channel.prediction.end": "channel:manage:predictions",
	"channel.hype_train.begin": "channel:read:hype_train",
	"channel.hype_train.progress": "channel:read:hype_train",
	"channel.hype_train.end": "channel:read:hype_train",
	"channel.goal.begin": "channel:read:goals",
	"channel.goal.progress": "channel:read:goals",
	"channel.goal.end": "channel:read:goals",
	}

var subscriptions : Array = [
	"chat.read",
	"chat.edit",
	"channel.update",
	"channel.follow",
	"channel.subscribe",
	"channel.subscription.end",
	"channel.subscription.gift",
	"channel.suscription.message",
	"channel.cheer",
	"channel.raid",
	"channel.ban",
	"channel.unban",
	"channel.moderate",
	"channel.moderator.add",
	"channel.moderator.removed",
	"channel.points_custom_reward.add",
	"channel.points_custom_reward.update",
	"channel.points_custom_reward.remove",
	"channel.points_custom_reward_redemption.add",
	"channel.points_custom_reward_redemption.update",
	"channel.poll.begin",
	"channel.poll.progress",
	"channel.poll.end",
	"channel.prediction.begin",
	"channel.prediction.progress",
	"channel.prediction.lock",
	"channel.prediction.end",
	"drop.entitlement.grant",
	"extension.bits_transaction.create",
	"channel.goal.begin",
	"channel.goal.progress",
	"channel.goal.end",
	"channel.hype_train.begin",
	"channel.hype_train.progress",
	"channel.hype_train.end",
	"stream.online",
	"stream.offline",
	"user.authorization.grant",
	"user.authorization.revoke",
	"user.update",
]

var __basic_scope : PoolStringArray = [
	CHAT_READ,
	CHAT_EDIT,
	CHANNEL_UPDATE,
	CHANNEL_FOLLOW, 
	CHANNEL_SUBSCRIBE, 
	CHANNEL_SUBSCRIPTION_GIFT, 
	CHANNEL_SUBSCRIPTION_MESSAGE, 
	CHANNEL_CHEER, 
	CHANNEL_RAID,
	CHANNEL_MODERATE,
	]


func get_scope(scope_ints : PoolStringArray) -> Dictionary:
	var sub_pool : PoolStringArray = []
	var scope_string = ""
	# Keep track of scopes already accounted for
	var check_dictionary : Dictionary = {}
	for i in scope_ints:
		var sub_type = self.subscriptions[str2var(i)]
		sub_pool.append(sub_type)
		if scopes.has(sub_type) and !check_dictionary.has(scopes[sub_type]):
			scope_string += scopes[sub_type] + " " 
			check_dictionary[scopes[sub_type]] = ""
	# Remove trailing space
	scope_string[-1] = ""
	var sub_dict : Dictionary = {}
	sub_dict["scope_string"] = scope_string
	sub_dict["subscriptions"] = sub_pool
	
	return sub_dict

func get_basic_scope() -> Dictionary:
	return get_scope(__basic_scope)
