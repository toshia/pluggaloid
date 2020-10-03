# frozen_string_literal: true

module Pluggaloid::Network
  def connect(other_vm)
    raise 'Try to connect across other network' if !vm_lonely? && !other_vm.vm_lonely? && (other_vm.vm_map & vm_map).empty?
    if vm_map.add?(other_vm)
      other_vm.connect(self)
      (vm_map - [other_vm]).each do |vm|
        vm.connect(other_vm)
      end
    end
    self
  end

  # childrenの結果とcounterpartを合わせたもの。
  def next_nodes(root_id)
    [
      *children(root_id),
      (counterpart if root_id == vmid)
    ].compact
  end

  # root_idに於いて、直下の子の配列を返す。
  # 直下の子は、最大で2つである。
  def children(root_id)
    depth = depth_in(root_id)
    addr = vmid ^ root_id
    subnet = addr[0..depth]
    ancestor = genus.select { |vm| (vm.vmid ^ root_id) > addr && subnet == (vm.vmid ^ root_id)[0..depth] }.sort_by { |vm| vm.vmid ^ root_id }
    [
      ancestor.find { |vm| (vm.vmid ^ root_id)[depth + 1] == 0 },
      ancestor.find { |vm| (vm.vmid ^ root_id)[depth + 1] == 1 }
    ].compact
  end

  def render_tree(root_id=vmid, depth=0, level=0)
    return if level > 8
    addr = vmid ^ root_id
    subnet = addr[0..depth]
    ancestor = genus.lazy.select { |vm| (vm.vmid ^ root_id) > addr && subnet == (vm.vmid ^ root_id)[0..depth] }
    lfts, rghs = ancestor.partition { |vm| (vm.vmid ^ root_id)[depth + 1] == 1 }

    lft = lfts.min_by { |vm| vm.vmid ^ root_id }
    lft&.render_tree(root_id, [next_depth(depth + 1, addr, lft.vmid ^ root_id), depth + 1].max, level + 1)

    puts '  ' * level + "%x\t(%08b/%0#{depth + 1}b)" % [vmid, addr, subnet]

    rgh = rghs.min_by { |vm| vm.vmid ^ root_id }
    rgh&.render_tree(root_id, next_depth(depth + 1, addr, rgh.vmid ^ root_id), level + 1)

    if root_id == vmid && depth == 0
      puts '----'
      counterpart&.render_tree(root_id, depth)
    end
  end

  def next_depth(start, vm_a, vm_b)
    (start..64).each do |i|
      return [i - 1, start].max if vm_a[i] != vm_b[i]
    end
  end

  # root_idの中で、selfが何階層目にいるかを返す。
  def depth_in(root_id)
    raise 'me not found' unless vm_map.include?(self)
    root = vm_map.find { |vm| vm.vmid == root_id }
    raise "root_id #{root_id} does not exists in this network (#{@vm_map})." unless root
    nex = root_id[0] == vmid[0] ? root : root.counterpart
    return 0 if nex == self
    depth = 0
    deck = vm_map.select { |vm| vm.vmid[0] == vmid[0] }.sort_by { |vm| vm.vmid ^ root_id }
    target_addr = vmid ^ root_id
    64.times do |level|
      return level if nex == self
      addr = nex.vmid ^ root_id
      subnet = addr[0..depth]
      nex, *deck = deck.select do |vm|
        va = vm.vmid ^ root_id
        va > addr && subnet == va[0..depth] && va[depth + 1] == target_addr[depth + 1]
      end
      depth = next_depth(depth + 1, addr, nex.vmid ^ root_id)
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

  def vm_lonely?
    vm_map.size == 1
  end

  def counterpart
    vm_map.select { |vm|
      (vm.vmid ^ vmid)[0] == 1
    }.min_by do |vm|
      vm.vmid ^ vmid
    end
  end
end
