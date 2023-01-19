@main
public struct WeeklyTweetCronJob {
    public private(set) var text = "Hello, World!"

    public static func main() {
        print(WeeklyTweetCronJob().text)
    }
}
