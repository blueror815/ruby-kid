class CreateTips < ActiveRecord::Migration
  def change
    create_table :tips do |t|
      t.string :title, null: false
      t.integer :order_index, default: 1
    end

    add_index_unless_exists :tips, :order_index

    [
        'Maximize your child\'s fun by getting more kids involved. Share with other parents.',
        'If you and your child use different devices, install the app on both.',
        'Enable notifications on your child\'s device. This is how they\'ll know when they\'ve been invited to trade.',
        'The first time your child posts, get involved. A little help goes a long way when choosing items and taking photos.',
        'Only post items that are clean and damage-free. No one wants junk!',
        'Tell your child to post a lot and post often! A variety of items will result in more trades.'
    ].each_with_index do|t, index|
      ::Tip.create(title: t, order_index: index + 1)
    end
  end
end
