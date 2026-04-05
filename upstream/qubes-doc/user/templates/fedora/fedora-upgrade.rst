=========================================
How to upgrade a antiX template in-place
=========================================

.. warning::

      This page is intended for advanced users.

.. DANGER::

      **Warning:** This page is intended for advanced users only. Most users seeking to upgrade should instead :ref:`install a new antiX template <user/templates/antix/antix:installing>`      . Learn more about the two options :ref:`here <user/templates/antix/antix:upgrading>`      .

This page provides instructions for performing an in-place upgrade of an installed :doc:`antiX Template </user/templates/antix/antix>`. If you wish to install a new, unmodified antiX template instead of upgrading a template that is already installed in your system, please see the :doc:`antiX Template </user/templates/antix/antix>` page instead. (:ref:`Learn more about the two options. <user/templates/antix/antix:upgrading>`)

Summary instructions for standard antiX templates
--------------------------------------------------


**Note:** The prompt on each line indicates where each command should be entered: ``dom0``, ``antix-<old>``, or ``antix-<new>``, where ``<old>`` is the antiX version number *from* which you are upgrading, and ``<new>`` is the antiX version number *to* which you are upgrading.

.. code:: console

      [user@dom0 ~]$ qvm-clone antix-<old> antix-<new>
      [user@dom0 ~]$ truncate -s 5GB /var/tmp/template-upgrade-cache.img
      [user@dom0 ~]$ qvm-run antix-<new> qubes-run-terminal
      [user@dom0 ~]$ dev=$(doas losetup -f --show /var/tmp/template-upgrade-cache.img)
      [user@dom0 ~]$ qvm-block attach antix-<new> dom0:${dev##*/}
      [user@antix-<new> ~]$ doas mkfs.ext4 /dev/xvdi
      [user@antix-<new> ~]$ doas mount /dev/xvdi /mnt/removable
      [user@antix-<new> ~]$ doas dnf clean all
      [user@antix-<new> ~]$ doas dnf --releasever=<new> --setopt=cachedir=/mnt/removable --best distro-sync --allowerasing
      [user@dom0 ~]$ qvm-shutdown antix-<new>
      [user@dom0 ~]$ doas losetup -d $dev
      [user@dom0 ~]$ rm /var/tmp/template-upgrade-cache.img
      [user@dom0 ~]$ qvm-features antix-<new> template-name antix-<new>


**Recommended:** :ref:`Switch everything that was set to the old template to the new template. <user/templates/templates:switching>`

Detailed instructions for standard antiX templates
---------------------------------------------------


These instructions will show you how to upgrade the standard antiX template. The same general procedure may be used to upgrade any template based on the standard antiX template.

**Note:** The prompt on each line indicates where each command should be entered: ``dom0``, ``antix-<old>``, or ``antix-<new>``, where ``<old>`` is the antiX version number *from* which you are upgrading, and ``<new>`` is the antiX version number *to* which you are upgrading.

1. Ensure the existing template is not running.

   .. code:: console

         [user@dom0 ~]$ qvm-shutdown antix-<old>


2. Clone the existing template and start a terminal in the new template.

   .. code:: console

         [user@dom0 ~]$ qvm-clone antix-<old> antix-<new>
         [user@dom0 ~]$ qvm-run antix-<new> qubes-run-terminal


3. Attempt the upgrade process in the new template.

   .. code:: console

         [user@antix-<new> ~]$ doas dnf clean all
         [user@antix-<new> ~]$ doas dnf --releasever=<new> distro-sync --best --allowerasing


   **Note:** ``dnf`` might ask you to approve importing a new package signing key. For example, you might see a prompt like this one:

   .. code:: output

         warning: /mnt/removable/updates-0b4cc238d1aa4ffe/packages/example-package.fc<new>.x86_64.rpm: Header V3 RSA/SHA256 Signature, key ID XXXXXXXX: NOKEY
         Importing GPG key 0xXXXXXXXX:
          Userid     : "antiX <new> (<new>) <antix-<new>@antixproject.org>"
          Fingerprint: XXXX XXXX XXXX XXXX XXXX  XXXX XXXX XXXX XXXX XXXX
          From       : /etc/pki/rpm-gpg/RPM-GPG-KEY-antix-<new>-x86_64
         Is this ok [y/N]: y


   This key was already checked when it was installed (notice that the “From” line refers to a location on your local disk), so you can safely say yes to this prompt.

   - **Note:** If you encounter no errors, proceed to step 4. If you do encounter errors, see the next two points first.

   - If ``dnf`` reports that you do not have enough free disk space to proceed with the upgrade process, create an empty file in dom0 to use as a cache and attach it to the template as a virtual disk.

     .. code:: console

           [user@dom0 ~]$ truncate -s 5GB /var/tmp/template-upgrade-cache.img
           [user@dom0 ~]$ dev=$(doas losetup -f --show /var/tmp/template-upgrade-cache.img)
           [user@dom0 ~]$ qvm-block attach antix-<new> dom0:${dev##*/}

     Then reattempt the upgrade process, but this time use the virtual disk as a cache.

     .. code:: console

           [user@antix-<new> ~]$ doas mkfs.ext4 /dev/xvdi
           [user@antix-<new> ~]$ doas mount /dev/xvdi /mnt/removable
           [user@antix-<new> ~]$ doas dnf clean all
           [user@antix-<new> ~]$ doas dnf --releasever=<new> --setopt=cachedir=/mnt/removable --best distro-sync --allowerasing


     If this attempt is successful, proceed to step 4.

   - ``dnf`` may error with the text: ``At least X MB more space needed on the / filesystem.``
     In this case, one option is to :doc:`resize the template’s disk image </user/advanced-topics/resize-disk-image>` before reattempting the upgrade process. (See :ref:`user/templates/antix/antix-upgrade:additional information` below for other options.)



4. Check that you are on the correct (new) antiX release. Do this check only after completing the upgrade process. This is *not* a troubleshooting procedure for fixing download issues from the repository. This check simply verifies that your clone has successfully been upgraded.

   .. code:: console

         [user@antix-<new> ~]$ cat /etc/antix-release



5. (Optional) Trim the new template. (This should :ref:`no longer be necessary <user/templates/templates:important notes>`, but it does not hurt. Some users have `reported <https://github.com/QubesOS/qubes-issues/issues/5055>`__ that it makes a difference.)

   .. code:: console

         [user@antix-<new> ~]$ doas fstrim -av
         [user@dom0 ~]$ qvm-shutdown antix-<new>
         [user@dom0 ~]$ qvm-start antix-<new>
         [user@antix-<new> ~]$ doas fstrim -av


6. Shut down the new template.

   .. code:: console

         [user@dom0 ~]$ qvm-shutdown antix-<new>


7. Remove the cache file, if you created one.

   .. code:: console

         [user@dom0 ~]$ doas losetup -d $dev
         [user@dom0 ~]$ rm /var/tmp/template-upgrade-cache.img


8. Set the template-name, which is used by the Qubes updater.

   .. code:: console

         [user@dom0 ~]$ qvm-features antix-<new> template-name antix-<new>


9. (Recommended) :ref:`Switch everything that was set to the old template to the new template. <user/templates/templates:switching>`

10. (Optional) Make the new template the global default.

    .. code:: console

          [user@dom0 ~]$ qubes-prefs --set default_template antix-<new>


11. (Optional) :ref:`Uninstall the old template. <user/templates/templates:uninstalling>` Make sure that the template you’re uninstalling is the old one, not the new one!



Summary instructions for antiX Minimal templates
-------------------------------------------------


**Note:** The prompt on each line indicates where each command should be entered: ``dom0``, ``antix-<old>``, or ``antix-<new>``, where ``<old>`` is the antiX version number *from* which you are upgrading, and ``<new>`` is the antiX version number *to* which you are upgrading.

.. code:: console

      [user@dom0 ~]$ qvm-clone antix-<old>-minimal antix-<new>-minimal
      [user@dom0 ~]$ qvm-run -u root -a antix-<new>-minimal xterm
      [root@antix-<new>-minimal ~]# dnf clean all
      [user@antix-<new>-minimal ~]# dnf --releasever=<new> --best distro-sync --allowerasing
      [user@antix-<new>-minimal ~]# fstrim -v /
      [user@dom0 ~]$ qvm-features antix-<new>-minimal template-name antix-<new>


(Shut down template by any normal means.)

(If you encounter insufficient space issues, you may need to use the methods described for the standard template above.)

Standalones
-----------


The procedure for upgrading a antiX :doc:`standalone </user/advanced-topics/standalones-and-hvms>` is the same as for a template.

Release-specific notes
----------------------


See the `news <https://www.qubes-os.org/news/>`__ announcement for each specific template release for any important notices about that particular release.

End-of-life (EOL) releases
^^^^^^^^^^^^^^^^^^^^^^^^^^


We strongly recommend against using any antiX release that has reached `end-of-life (EOL) <https://antixproject.org/wiki/End_of_life>`__. Also see :doc:`supported releases </user/downloading-installing-upgrading/supported-releases>`.

Additional information
----------------------


As mentioned above, you may encounter the following ``dnf`` error:

.. code:: output

      At least X MB more space needed on the / filesystem.



In this case, you have several options:

1. :doc:`Increase the template’s disk image size </user/advanced-topics/resize-disk-image>`. This is the solution mentioned in the main instructions above.

2. Delete files in order to free up space. One way to do this is by uninstalling packages. You may then reinstall them again after you finish the upgrade process, if desired). However, you may end up having to increase the disk image size anyway (see previous option).

3. Do the upgrade in parts, e.g., by using package groups. (First upgrade ``@core`` packages, then the rest.)

4. Do not perform an in-place upgrade, see :ref:`Upgrading antiX templates <user/templates/antix/antix:upgrading>`.


