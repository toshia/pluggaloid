# Pluggaloid

mikutterのプラグイン機構です。
登録したプラグイン同士がイベントを使って通信できるようになります。

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'pluggaloid'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install pluggaloid

## Usage

```ruby
require 'pluggaloid'

main = Pluggaloid.new(Delayer.generate_class(priority: %i<high normal low>, default: :normal))

main.Plugin.create(:write_to_stdout) do
  on_logging do |message|
    puts "logging: #{message}"
  end
end

main.Plugin.call(:logging, "boot.")
main.Plugin.call(:logging, "event test.")
main.Plugin.call(:logging, "exit.")

main.Delayer.run while not main.Delayer.empty?
```

### Pluggaloid::new

Pluggaloid::newは、プラグイン機構を制御するためのDelayer, Plugin, Event, Listener, Filterのサブクラスを新しく作って返すメソッドです。
戻り値はStructで、それぞれのクラス名がメンバの名前になっています。

| Member   | Description                         |
|----------|-------------------------------------|
| Delayer  | Pluggaloid::new に渡したDelayer     |
| Plugin   | Pluggaloid::Plugin のサブクラス     |
| Event    | Pluggaloid::Event のサブクラス      |
| Listener | Pluggaloid::Listener のサブクラス   |
| Filter   | Pluggaloid::Filter のサブクラス     |

コンストラクタの唯一の引数には `Delayer.generate_class(priority: %i<high normal low>, default: :normal)`のように、優先順位付きでデフォルト優先度が設定されたDelayerを渡します。

## Reactive Filter

### each_slice(times)

_times_ 要素ずつブロックに渡して繰り返します。
要素数が _times_ で割り切れないときは、要素が _times_ 個になるまで待ちます。

### throttle(sec)

最後に要素を受信してから、 _sec_ 秒の間に受信した要素を捨てます。

### debounce(sec)

_sec_ 秒要素を受信しなかった場合、最後の要素を送信する。

### buffer(sec)

_sec_ 秒の間に受信した要素を、 _sec_ 秒ごとに配列にまとめて送信する。

## Contributing

1. Fork it ( https://github.com/toshia/pluggaloid/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
