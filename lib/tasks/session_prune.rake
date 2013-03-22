namespace :rack_cas do
  namespace :sessions do
    namespace :prune do
      desc 'Delete old sessions from an Active Record session store'
      task :active_record, [:after] => :environment do |t, args|
        after = (Time.parse(args.after.to_s) unless args.after.nil?)
        RackCAS::ActiveRecordStore.prune after
      end

      desc 'Delete old sessions from an Mongoid session store'
      task :mongoid, [:after] => :environment do |t, args|
        after = (Time.parse(args.after.to_s) unless args.after.nil?)
        RackCAS::MongoidStore.prune after
      end
    end
  end
end