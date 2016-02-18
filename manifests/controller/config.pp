# Private class
class slurm::controller::config {

  file { 'StateSaveLocation':
    ensure  => 'directory',
    path    => $slurm::state_save_location,
    owner   => $slurm::slurm_user,
    group   => $slurm::slurm_user_group,
    mode    => '0700',
    require => File[$slurm::shared_state_dir],
  }

  file { 'JobCheckpointDir':
    ensure  => 'directory',
    path    => $slurm::job_checkpoint_dir,
    owner   => $slurm::slurm_user,
    group   => $slurm::slurm_user_group,
    mode    => '0700',
    require => File[$slurm::shared_state_dir],
  }

  if $slurm::manage_state_dir_nfs_mount {
    mount { 'StateSaveLocation':
      ensure  => 'mounted',
      name    => $slurm::state_save_location,
      atboot  => true,
      device  => $slurm::state_dir_nfs_device,
      fstype  => 'nfs',
      options => $slurm::state_dir_nfs_options,
      require => File['StateSaveLocation'],
    }
  }

  if $slurm::manage_job_checkpoint_dir_nfs_mount {
    mount { 'JobCheckpointDir':
      ensure  => 'mounted',
      name    => $slurm::job_checkpoint_dir,
      atboot  => true,
      device  => $slurm::job_checkpoint_dir_nfs_device,
      fstype  => 'nfs',
      options => $slurm::job_checkpoint_dir_nfs_options,
      require => File['JobCheckpointDir'],
    }
  }

  if $::osfamily == 'RedHat' and $::operatingsystemmajrelease == '7' {
    augeas { 'slurmctld.service':
      context => "$slurm::slurm_augeas_systemd_dir/slurmctld.service",
      changes => [
        "set Unit/ConditionPathExists $slurm::slurm_conf_path",
        "set Service/PIDFile $slurm::pid_dir/slurmctld.pid",
      ],
      notify  => Service['slurmctld'],
    }
  }

  if $slurm::manage_logrotate {
    #Refer to: http://slurm.schedmd.com/slurm.conf.html#SECTION_LOGGING
    logrotate::rule { 'slurmctld':
      path          => $slurm::slurmctld_log_file,
      compress      => true,
      missingok     => true,
      copytruncate  => false,
      delaycompress => false,
      ifempty       => false,
      rotate        => '10',
      sharedscripts => true,
      size          => '10M',
      create        => true,
      create_mode   => '0640',
      create_owner  => $slurm::slurm_user,
      create_group  => 'root',
      postrotate    => $slurm::_logrotate_slurm_postrotate,
    }
  }

}
