class_name FileSystemSocial extends FileSystem
## FileSystem that uses SocialPlatformManager for saving files in the cloud if possible.


func _get_data(file_name:String, success_callback:Callable, fail_callback:Callable):
	if not SocialPlatformManager.is_initialized:
		await SocialPlatformManager.initialized

	if SocialPlatformManager.supports_cloud_save():
		SocialPlatformManager.get_cloud_save_data(file_name, success_callback, fail_callback)
	else:
		fail_callback.call("Not supported")


func _save_data(file_name:String, data:String, success_callback:Callable, fail_callback:Callable):
	if not SocialPlatformManager.is_initialized:
		await SocialPlatformManager.initialized

	if SocialPlatformManager.supports_cloud_save():
		SocialPlatformManager.save_cloud_save_data(file_name, data, success_callback, fail_callback)
	else:
		fail_callback.call("Not supported")


func _clear_data(file_name:String, success_callback:Callable, fail_callback:Callable):
	if not SocialPlatformManager.is_initialized:
		await SocialPlatformManager.initialized

	if SocialPlatformManager.supports_cloud_save():
		SocialPlatformManager.clear_cloud_save_data(file_name, success_callback, fail_callback)
	else:
		fail_callback.call("Not supported")
