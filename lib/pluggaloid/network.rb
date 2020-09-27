# frozen_string_literal: true

module Pluggaloid::Network
  def connect(other_vm)
    if vm_map.add?(other_vm)
      other_vm.connect(self)
      (vm_map - [other_vm]).each do |vm|
        vm.connect(other_vm)
      end
      # other_vm.connect(self)
      # children(vmid).each do |vm|
      #   vm.notify_network_added_vm(other_vm, root_id: vmid)
      # end
    end
    self
  end

  def notify_network_added_vm(new_vm, root_id:)
    if vm_map.add?(new_vm)
      children(root_id).each do |vm|
        vm.notify_network_added_vm(new_vm, root_id: netmask)
      end
    end
  end

  # root_idに於いて、直下の子の配列を返す。
  # 直下の子は、最大で2つである。
  def children(root_id)
    depth = depth_in(root_id)
    addr = vmid ^ root_id
    subnet = addr[0..(depth)]
    ancestor = genus.lazy.select { |vm| (vm.vmid ^ root_id) > addr && subnet == (vm.vmid ^ root_id)[0..depth] }
    lfts, rghs = ancestor.partition { |vm| (vm.vmid ^ root_id)[depth + 1] == 1 }
    [lfts.min_by { |vm| vm.vmid ^ root_id }, rghs.min_by { |vm| vm.vmid ^ root_id }].compact
  end

  def call_event_in_child_vm(event_entity)
    # if @vm_map.size >= 2
    #   (@vm_map - [self]).each(&event_entity.method(:fire))
    # end
    mask = event_entity.from.vmid.method(:^)
    my_nwid = mask.(vmid)

    my_depth = depth_in(event_entity.from.vmid)

    vm_map.map { |vm|
      [mask.(vm.vmid), vm]
    }
  end

  def render_tree(root_id=vmid, depth=0, level=0)
    return if level > 8
    addr = vmid ^ root_id
    subnet = addr[0..(depth)]
    ancestor = genus.lazy.select { |vm| (vm.vmid ^ root_id) > addr && subnet == (vm.vmid ^ root_id)[0..depth] }
    lfts, rghs = ancestor.partition { |vm| (vm.vmid ^ root_id)[depth + 1] == 1 }

    lft = lfts.min_by { |vm| vm.vmid ^ root_id }
    lft&.render_tree(root_id, [next_depth(depth+1, addr, lft.vmid ^ root_id), depth+1].max, level+1)

    puts '  ' * level + "%x\t(%08b/%0#{depth+1}b)" % [vmid, addr, subnet]

    rgh = rghs.min_by { |vm| vm.vmid ^ root_id }
    rgh&.render_tree(root_id, next_depth(depth+1, addr, rgh.vmid ^ root_id), level+1)

    if root_id == vmid && depth == 0
      puts '----'
      counterpart&.render_tree(root_id, depth)
    end
  end

  def next_depth(start, a, b)
    (start..64).each do |i|
      return [i - 1, start].max if a[i] != b[i]
    end
  end

  # root_idの中で、selfが何階層目にいるかを返す。
  def depth_in(root_id)
    root = vm_map.find { |vm| vm.vmid == root_id }
    nex = root_id[0] == vmid[0] ? root : root.counterpart
    return 0 if nex == self
    level = depth = 0
    deck = vm_map.select { |vm| vm.vmid[0] == vmid[0] }.sort_by { |vm| vm.vmid ^ root_id }
    target_addr = vmid ^ root_id
    loop do
      return level if nex == self
      addr = nex.vmid ^ root_id
      subnet = addr[0..depth]
      nex, *deck = deck.select do |vm|
        va = vm.vmid ^ root_id
        va > addr && subnet == va[0..depth] && va[depth + 1] == target_addr[depth + 1]
      end
      depth = next_depth(depth + 1, addr, nex.vmid ^ root_id)
      level += 1
    end
  end

  def network_hash
    vm_map.map(&:vmid).inject(&:^)
  end

  def vm_map
    @vm_map ||= Set[self]
  end

  def genus
    vm_map - [self]
  end

  def counterpart
    vm_map.select { |vm|
      (vm.vmid ^ vmid)[0] == 1
    }.min_by { |vm|
      vm.vmid ^ vmid
    }
  end
end
