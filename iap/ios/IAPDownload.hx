package iap.ios;

class IAPDownload
{
	public final downloadId:String;
	public final contentIdentifier:String;
	public final contentURL:String;
	public final progress:Float;

	public function new(json:Dynamic):Void
	{
		downloadId = json.downloadId;
		contentIdentifier = json.contentIdentifier;
		contentURL = json.contentURL;
		progress = json.progress;
	}
}
