require "log4r"

require_relative "driver"
require_relative "plugin"

require "vagrant/util/platform"
require "vagrant/util/powershell"

module VagrantPlugins
  module HyperV
    class Provider < Vagrant.plugin("2", :provider)
      attr_reader :driver

      def initialize(machine)
        @driver  = Driver.new
        @machine = machine

        if !Vagrant::Util::Platform.windows?
          raise Errors::WindowsRequired
        end

        if !Vagrant::Util::Platform.windows_admin?
          raise Errors::AdminRequired
        end

        if !Vagrant::Util::PowerShell.available?
          raise Errors::PowerShellRequired
        end
      end

      def action(name)
        # Attempt to get the action method from the Action class if it
        # exists, otherwise return nil to show that we don't support the
        # given action.
        action_method = "action_#{name}"
        return Action.send(action_method) if Action.respond_to?(action_method)
        nil
      end

      def state
        # Run a custom action we define called "read_state" which does
        # what it says. It puts the state in the `:machine_state_id`
        # key in the environment.
        env = @machine.action("read_state")
        state_id = env[:machine_state_id]

        # Get the short and long description
        short = "Machine's current state is #{state_id}"
        long  = ""

        # Return the MachineState object
        Vagrant::MachineState.new(state_id, short, long)
      end

      def to_s
        id = @machine.id.nil? ? "new" : @machine.id
        "Hyper-V (#{id})"
      end

      def ssh_info
        # Run a custom action called "read_guest_ip" which does what it
        # says and puts the resulting SSH info into the `:machine_ssh_info`
        # key in the environment.
        env = @machine.action("read_guest_ip")
        if env[:machine_ssh_info]
          env[:machine_ssh_info].merge!(:port => 22)
        end
      end
    end
  end
end
