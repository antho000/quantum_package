program cisd
  implicit none
  integer                        :: i,k

  
  double precision, allocatable  :: pt2(:), norm_pert(:), H_pert_diag(:)
  integer                        :: N_st, iter
  character*(64)                 :: perturbation
  N_st = N_states
  allocate (pt2(N_st), norm_pert(N_st), H_pert_diag(N_st))
  
  pt2 = 1.d0
  perturbation = "epstein_nesbet"
  do while (maxval(abs(pt2(1:N_st))) > 1.d-6)
    call H_apply_cisd_selection(perturbation,pt2, norm_pert, H_pert_diag,  N_st)
    call diagonalize_CI
    print *,  'N_det    = ', N_det
    print *,  'N_states = ', N_states
    print *,  'PT2      = ', pt2
    print *,  'E        = ', CI_energy
    print *,  'E+PT2    = ', CI_energy+pt2
    if (abort_all) then
      exit
    endif
  enddo
  deallocate(pt2,norm_pert,H_pert_diag)
end
